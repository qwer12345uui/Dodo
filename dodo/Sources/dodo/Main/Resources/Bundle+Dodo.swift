//
//  Bundle+Dodo.swift
//
//
//  Created by Noah Little on 6/5/2023.
//

import Foundation
import GSCore

extension Bundle {
    static var dodo: Bundle {
        let path = "/Library/PreferenceBundles/dodo.bundle/".dodoRootPath
        return Bundle(path: path) ?? .main
    }
}
