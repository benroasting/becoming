//
//  APIClient+Values.swift
//  Becoming
//
//  Created by Ben Young on 8/7/26.
//

import Foundation

nonisolated struct ValueRequest: Encodable {
    let title: String
    let description: String
}

protocol ValueServicing {
    func values() async throws -> [Value]
    func value(id: String) async throws -> Value
    func createValue(_ request: ValueRequest) async throws -> Value
    func updateValue(id: String, _ request: ValueRequest) async throws -> Value
    func abandonValue(id: String) async throws
}

extension APIClient: ValueServicing {
    func values() async throws -> [Value] {
        try await get("/values")
    }
    
    func value(id: String) async throws -> Value {
        try await get("/values/\(id)")
    }
    
    func createValue(_ request: ValueRequest) async throws -> Value {
        try await post("/values", body: request)
    }
    
    func updateValue(id: String, _ request: ValueRequest) async throws -> Value {
        try await put("/values/\(id)", body: request)
    }
    
    func abandonValue(id: String) async throws {
        try await post("/values/\(id)/abandon")
    }
}
