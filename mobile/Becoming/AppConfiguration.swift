//
//  AppConfiguration.swift
//  Becoming
//
//  Created by Ben Young on 9/5/26.
//

import Foundation

nonisolated enum AppConfiguration {
    static let apiBaseURL: URL = URL(string: "http://localhost:8081/api/v1")!
}
