//
//  Bundle+Dodo.swift
//
//
//  Created by Noah Little on 25/6/2023.
//

import Foundation

extension Bundle {
    static var dodo: Bundle {
        let path = "/Library/Application Support/Dodo/Dodo.bundle".dodoRootPath
        return Bundle(path: path) ?? .main
    }
}
