//
//  APIError.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

enum APIError: Error {
    case requestFailed(underlying: any Error)
    case httpError(statusCode: Int, message: String)
    case encodingFailed(underlying: any Error)
    case decodingFailed(underlying: any Error)
    case invalidResponse
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .requestFailed(underlying: let error):
            return "Request failed: \(error.localizedDescription)"
        case .httpError(statusCode: let code, message: let message):
            return "HTTP error: \(code) - \(message)"
        case .encodingFailed(underlying: let error):
            return "Encoding failed: \(error)"
        case .decodingFailed(underlying: let error):
            return "Decoding failed: \(error)"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}
