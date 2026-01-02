//
//  GoogleAIService.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import Foundation

struct GoogleAIMessage: Codable {
  let role: String
  let content: String
}

struct GoogleAIRequest: Codable {
  let model: String
  let messages: [GoogleAIMessage]
  let temperature: Double
  let maxOutputTokens: Int
  
  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case temperature
    case maxOutputTokens = "max_output_tokens"
  }
}

struct GoogleAIContent: Codable {
  let parts: [GoogleAIPart]
}

struct GoogleAIPart: Codable {
  let text: String
}

struct GoogleAICandidate: Codable {
  let content: GoogleAIContent
}

struct GoogleAIResponse: Codable {
  let candidates: [GoogleAICandidate]
  let usageMetadata: GoogleAIUsageMetadata?
  
  enum CodingKeys: String, CodingKey {
    case candidates
    case usageMetadata = "usageMetadata"
  }
  
  var text: String? {
    candidates.first?.content.parts.first?.text
  }
}

struct GoogleAIUsageMetadata: Codable {
  let promptTokenCount: Int
  let candidatesTokenCount: Int
  let totalTokenCount: Int
  
  enum CodingKeys: String, CodingKey {
    case promptTokenCount = "prompt_token_count"
    case candidatesTokenCount = "candidates_token_count"
    case totalTokenCount = "total_token_count"
  }
}

enum GoogleAIError: LocalizedError {
  case invalidAPIKey
  case networkError(String)
  case invalidResponse
  case apiError(String)
  
  var errorDescription: String? {
    switch self {
    case .invalidAPIKey:
      return "Invalid Google AI API key"
    case .networkError(let message):
      return "Network error: \(message)"
    case .invalidResponse:
      return "Invalid response from Google AI API"
    case .apiError(let message):
      return "API error: \(message)"
    }
  }
}

struct GoogleAIService {
  var apiKey: @Sendable () -> String
  var generateContent: @Sendable (
    _ model: String,
    _ messages: [GoogleAIMessage],
    _ temperature: Double,
    _ maxTokens: Int
  ) async throws -> String
  
  var listModels: @Sendable () async throws -> [String]
}

extension GoogleAIService: DependencyKey {
  static let liveValue = Self(
    apiKey: {
      UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
    },
    generateContent: { model, messages, temperature, maxTokens in
      let apiKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
      guard !apiKey.isEmpty else {
        throw GoogleAIError.invalidAPIKey
      }
      
      let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      
      let googleRequest = GoogleAIRequest(
        model: model,
        messages: messages,
        temperature: temperature,
        maxOutputTokens: maxTokens
      )
      
      request.httpBody = try JSONEncoder().encode(googleRequest)
      
      let (data, response) = try await URLSession.shared.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw GoogleAIError.invalidResponse
      }
      
      if httpResponse.statusCode != 200 {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw GoogleAIError.apiError("Status code: \(httpResponse.statusCode), Message: \(errorMessage)")
      }
      
      let googleResponse = try JSONDecoder().decode(GoogleAIResponse.self, from: data)
      
      guard let text = googleResponse.text else {
        throw GoogleAIError.invalidResponse
      }
      
      return text
    },
    listModels: {
      let apiKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
      guard !apiKey.isEmpty else {
        throw GoogleAIError.invalidAPIKey
      }
      
      let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)")!
      let (data, response) = try await URLSession.shared.data(from: url)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw GoogleAIError.invalidResponse
      }
      
      if httpResponse.statusCode != 200 {
        throw GoogleAIError.apiError("Status code: \(httpResponse.statusCode)")
      }
      
      struct ModelsResponse: Codable {
        let models: [ModelInfo]
      }
      
      struct ModelInfo: Codable {
        let name: String
      }
      
      let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
      return modelsResponse.models.map { $0.name }
    }
  )
  
  static let testValue = Self(
    apiKey: { "test-key" },
    generateContent: { _, _, _, _ in
      "Test response from Google AI"
    },
    listModels: {
      ["gemini-2.5-flash", "gemini-2.5-pro"]
    }
  )
}

extension DependencyValues {
  var googleAIService: GoogleAIService {
    get { self[GoogleAIService.self] }
    set { self[GoogleAIService.self] = newValue }
  }
}
