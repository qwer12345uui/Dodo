//
//  WeatherView.ViewModel.swift
//  
//
//  Created by Noah Little on 22/11/2022.
//
//  [FIX 2026-08] RootHide iOS 15 下拉卡注销修复：
//  崩溃日志显示 SpringBoard 主线程 60s 无响应被 watchdog 强杀。
//  根因：init() 在主线程同步调用 locationProvider.set(isUpdatingLocation:) 启动
//  CLLocationManager，与 locationd 的 XPC 握手在 RootHide 环境下可能无限期阻塞
//  主线程。所有定位/天气相关操作全部移入后台队列，主线程只负责 Combine 回传 UI。

import Foundation
import DodoC
import GSWeather
import GSCore
import Combine
import CoreLocation

// MARK: - Internal

extension WeatherView {
    final class ViewModel: ObservableObject {
        enum Constants {
            static let minMinutesForRefresh = 30
        }
        
        @Published
        private(set) var celsiusWeatherString: String?
        
        @Published
        private(set) var fahrenheitWeatherString: String?
        
        @Published
        private(set) var celsiusHighLowString: String?
        
        @Published
        private(set) var fahrenheitHighLowString: String?
        
        @Published
        private(set) var isDisplayingCelsius = true
        
        @Published
        private(set) var sunriseString: String?
        
        @Published
        private(set) var sunsetString: String?
        
        var weatherString: String? {
            guard let temp = isDisplayingCelsius ? celsiusWeatherString : fahrenheitWeatherString else { return nil }
            let highLow = isDisplayingCelsius ? celsiusHighLowString : fahrenheitHighLowString
            let result = [temp, highLow]
                .compactMap { $0 }
                .joined(separator: " ")
            return result
        }
        
        private var bag: Set<AnyCancellable> = []
        private var temperature = CurrentValueSubject<Temperature?, Never>(nil)
        private var high = CurrentValueSubject<Temperature?, Never>(nil)
        private var low = CurrentValueSubject<Temperature?, Never>(nil)
        private var location = CurrentValueSubject<CLLocation?, Never>(nil)
        private var weather = CurrentValueSubject<WeatherModel?, Never>(PreferenceManager.shared.defaults.weather(forKey: Keys.cachedWeather))
        
        private let locationProvider: LocationProvider
        private let weatherProvider: WeatherProvider
        private let settings = PreferenceManager.shared.settings.weather
        
        /// [FIX] 专用后台队列，所有 LocationProvider / WeatherProvider 调用都在这里执行，
        /// 避免在主线程上做 locationd XPC / 网络触发的同步工作。
        private let weatherQueue = DispatchQueue(label: "com.ginsu.dodo.weather", qos: .utility)
        
        init() {
            self.locationProvider = .init()
            self.weatherProvider = .init()
            
            if settings.tapAction == .celsiusToFahrenheit {
                self.isDisplayingCelsius = PreferenceManager.shared.defaults.bool(forKey: Keys.isDisplayingCelsius)
            } else {
                self.isDisplayingCelsius = currentTemperatureUnit() == .celsius
            }
            
            subscribe()
            
            // [FIX] 原代码在主线程直接启动定位：
            //   locationProvider.set(isUpdatingLocation: true)
            // CLLocationManager 启动会同步与 locationd 握手，RootHide iOS 15 上可阻塞
            // SpringBoard 主线程超过 60 秒触发 watchdog（下拉通知中心时锁屏视图重建
            // 会重新走到这里，这就是"下拉卡注销、触发时间不确定"的来源）。
            weatherQueue.async { [locationProvider] in
                locationProvider.set(isUpdatingLocation: true)
            }
        }
        
        func updateWeather() {
            guard canFetchWeather(), let location = location.value
            else { return }
            
            // [FIX] 天气抓取放后台队列执行。
            weatherQueue.async { [weatherProvider] in
                weatherProvider.fetchWeather(provider: .meteo(
                    location: location,
                    timezone: .current
                ))
            }
        }
        
        func onTapWeather() {
            switch settings.tapAction {
            case .celsiusToFahrenheit:
                isDisplayingCelsius.toggle()
                HapticManager.playHaptic(withIntensity: .success)
            case .refresh:
                updateWeather()
                HapticManager.playHaptic(withIntensity: .success)
            case .none:
                break
            }
        }
        
        func openWeatherApp() {
            AppsManager.shared.open(app: .defined(.weather))
            HapticManager.playHaptic(withIntensity: .custom(.medium))
        }
    }
}

// MARK: - Private

private extension WeatherView.ViewModel {
    typealias TemperatureUnit = WeatherProvider.TemperatureUnit
    
    func subscribe() {
        // Store weather locally
        weatherProvider.currentWeatherPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] in self?.weather.send($0)}
            .store(in: &bag)
        
        // Store weather locally for display
        weather
            .compactMap { model -> (celsius: String, fahrenheit: String)? in
                guard let name = model?.locationName,
                      let temperature = model?.temperature
                else { return nil }
                return (
                    "\(name) | \(temperature.celsius)",
                    "\(name) | \(temperature.fahrenheit)"
                )
            }
            .sink { [weak self] celsius, fahrenheit in
                self?.celsiusWeatherString = celsius
                self?.fahrenheitWeatherString = fahrenheit
            }
            .store(in: &bag)
        
        // Store high/low locally for display
        if settings.isVisibleHighLow {
            weather
                .compactMap { [weak self] model -> (celsius: String, fahrenheit: String)? in
                    guard let self,
                          let high = model?.high,
                          let low = model?.low
                    else { return nil }
                    
                    return (
                        highLowStringBuilder(high: high, low: low, isCelsius: true),
                        highLowStringBuilder(high: high, low: low, isCelsius: false)
                    )
                }
                .sink { [weak self] celsius, fahrenheit in
                    self?.celsiusHighLowString = celsius
                    self?.fahrenheitHighLowString = fahrenheit
                }
                .store(in: &bag)
        }
        
        if settings.isVisibleSunriseSunset {
            weather
                .compactMap { model -> (sunrise: String, sunset: String)? in
                    guard let model else { return nil }
                    return (
                        Formatters.time.string(from: model.sunrise),
                        Formatters.time.string(from: model.sunset)
                    )
                }
                .sink { [weak self] sunrise, sunset in
                    self?.sunriseString = sunrise
                    self?.sunsetString = sunset
                }
                .store(in: &bag)
        }
        
        // Enable/Disable location monitoring depending on screen on state
        // [FIX] 屏幕开关时的定位切换同样不能在主线程同步执行。
        LocalState.shared.$isScreenOff
            .sink { [weak self] isScreenOff in
                guard let self else { return }
                self.weatherQueue.async {
                    self.locationProvider.set(isUpdatingLocation: !isScreenOff)
                }
            }
            .store(in: &bag)
        
        // Store location locally
        locationProvider.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.location.send($0)}
            .store(in: &bag)
        
        // Caching
        weather
            .sink { PreferenceManager.shared.defaults.set(weather: $0, forKey: Keys.cachedWeather) }
            .store(in: &bag)
        
        $isDisplayingCelsius
            .sink { PreferenceManager.shared.defaults.set($0, forKey: Keys.isDisplayingCelsius) }
            .store(in: &bag)
    }
    
    func canFetchWeather() -> Bool {
        guard let weather = weather.value else { return true }
        let minutes = Calendar.current.dateComponents(
            [.minute],
            from: weather.date,
            to: Date()
        ).minute ?? .zero
        return minutes >= Constants.minMinutesForRefresh
    }
    
    func currentTemperatureUnit() -> TemperatureUnit? {
        guard let provider = WeatherService.shared()?.temperatureUnitProvider else { return nil }
        
        switch provider.userTemperatureUnit {
        case 2: return .celsius
        case 1: return .fahrenheit
        default: return nil
        }
    }
    
    func highLowStringBuilder(high: Temperature, low: Temperature, isCelsius: Bool) -> String {
        let highTemp = isCelsius ? high.celsius : high.fahrenheit
        let lowTemp = isCelsius ? low.celsius : low.fahrenheit
        return Copy.Weather.highLow(highTemp, lowTemp)
    }
}
