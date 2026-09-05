//
//  APIClient.swift
//  Becoming
//
//  Created by Ben Young on 8/7/26.
//

import Foundation

nonisolated final class APIClient {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }
    
    private func perform(
        _ method: HTTPMethod,
        path: String,
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method.rawValue
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let data:Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            try Task.checkCancellation()
            throw APIError.requestFailed(underlying: error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
        return data
    }
    
    private func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: Data? = nil
    ) async throws -> T {
        let data = try await perform(method, path: path, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }
    
    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(.get, path: path)
    }
    
    private func encode(_ value: some Encodable) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw APIError.encodingFailed(underlying: error)
        }
    }
    
    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(.post, path: path, body:encode(body))
    }
    
    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(.put, path: path, body:encode(body))
    }
    
    func post(_ path: String) async throws {
        _ = try await perform(.post, path: path)
    }
    
    func delete(_ path: String) async throws {
        _ = try await perform(.delete, path: path)
    }
}
