//
//  WeatherView.ViewModel.swift
//  Dodo
//
//  Restored and hardened for iOS 15 SpringBoard.
//

import Foundation
import DodoC
import GSWeather
import GSCore
import Combine
import CoreLocation

extension WeatherView {
    final class ViewModel: ObservableObject {
        enum Constants {
            static let minMinutesForRefresh = 30
        }

        @Published private(set) var celsiusWeatherString: String?
        @Published private(set) var fahrenheitWeatherString: String?
        @Published private(set) var celsiusHighLowString: String?
        @Published private(set) var fahrenheitHighLowString: String?
        @Published private(set) var isDisplayingCelsius = true
        @Published private(set) var sunriseString: String?
        @Published private(set) var sunsetString: String?

        var weatherString: String? {
            guard let temperature = isDisplayingCelsius ? celsiusWeatherString : fahrenheitWeatherString else {
                return nil
            }
            let highLow = isDisplayingCelsius ? celsiusHighLowString : fahrenheitHighLowString
            return [temperature, highLow].compactMap { $0 }.joined(separator: " ")
        }

        private var bag: Set<AnyCancellable> = []
        private let location = CurrentValueSubject<CLLocation?, Never>(nil)
        private let weather = CurrentValueSubject<WeatherModel?, Never>(
            PreferenceManager.shared.defaults.weather(forKey: Keys.cachedWeather)
        )

        private let locationProvider: LocationProvider
        private let weatherProvider: WeatherProvider
        private let settings = PreferenceManager.shared.settings.weather

        // Location and weather services can synchronously contact locationd or
        // start network work. Keep that work off SpringBoard's watchdog-monitored
        // main queue and serialize all provider access on one queue.
        private let weatherQueue = DispatchQueue(label: "com.ginsu.dodo.weather", qos: .utility)

        init() {
            locationProvider = .init()
            weatherProvider = .init()

            if settings.tapAction == .celsiusToFahrenheit {
                isDisplayingCelsius = PreferenceManager.shared.defaults.bool(forKey: Keys.isDisplayingCelsius)
            } else {
                isDisplayingCelsius = currentTemperatureUnit() == .celsius
            }

            subscribe()
            weatherQueue.async { [locationProvider] in
                locationProvider.set(isUpdatingLocation: true)
            }
        }

        func updateWeather() {
            guard canFetchWeather(), let currentLocation = location.value else { return }

            weatherQueue.async { [weatherProvider] in
                weatherProvider.fetchWeather(provider: .meteo(
                    location: currentLocation,
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

private extension WeatherView.ViewModel {
    typealias TemperatureUnit = WeatherProvider.TemperatureUnit

    func subscribe() {
        weatherProvider.currentWeatherPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] in self?.weather.send($0) }
            .store(in: &bag)

        weather
            .compactMap { model -> (celsius: String, fahrenheit: String)? in
                guard let name = model?.locationName,
                      let temperature = model?.temperature else {
                    return nil
                }
                return ("\(name) | \(temperature.celsius)", "\(name) | \(temperature.fahrenheit)")
            }
            .sink { [weak self] celsius, fahrenheit in
                self?.celsiusWeatherString = celsius
                self?.fahrenheitWeatherString = fahrenheit
            }
            .store(in: &bag)

        if settings.isVisibleHighLow {
            weather
                .compactMap { [weak self] model -> (celsius: String, fahrenheit: String)? in
                    guard let self,
                          let high = model?.high,
                          let low = model?.low else {
                        return nil
                    }
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

        LocalState.shared.$isScreenOff
            .sink { [weak self] isScreenOff in
                guard let self else { return }
                weatherQueue.async {
                    self.locationProvider.set(isUpdatingLocation: !isScreenOff)
                }
            }
            .store(in: &bag)

        locationProvider.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentLocation in
                self?.location.send(currentLocation)
                if self?.settings.isActiveWeatherAutomaticRefresh == true {
                    self?.updateWeather()
                }
            }
            .store(in: &bag)

        weather
            .sink { PreferenceManager.shared.defaults.set(weather: $0, forKey: Keys.cachedWeather) }
            .store(in: &bag)

        $isDisplayingCelsius
            .sink { PreferenceManager.shared.defaults.set($0, forKey: Keys.isDisplayingCelsius) }
            .store(in: &bag)
    }

    func canFetchWeather() -> Bool {
        guard let cachedWeather = weather.value else { return true }
        let minutes = Calendar.current.dateComponents(
            [.minute],
            from: cachedWeather.date,
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
        let highTemperature = isCelsius ? high.celsius : high.fahrenheit
        let lowTemperature = isCelsius ? low.celsius : low.fahrenheit
        return Copy.Weather.highLow(highTemperature, lowTemperature)
    }
}
