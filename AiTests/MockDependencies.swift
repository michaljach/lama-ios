//
//  MockDependencies.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Mock UserDefaultsService

extension UserDefaultsService {
  static var mockWithCustomValues: (String) -> UserDefaultsService {
    return { apiKey in
      var store: [String: Any] = [:]
      
      return UserDefaultsService(
        getDefaultModel: { store["defaultModel"] as? String ?? "openai/gpt-oss:120b" },
        setDefaultModel: { value in store["defaultModel"] = value },
        getTemperature: { store["temperature"] as? Double ?? 0.7 },
        setTemperature: { value in store["temperature"] = value },
        getMaxTokens: { store["maxTokens"] as? Int ?? 640 },
        setMaxTokens: { value in store["maxTokens"] = value },
        isWebSearchEnabled: { store["webSearchEnabled"] as? Bool ?? true },
        setWebSearchEnabled: { value in store["webSearchEnabled"] = value },
        resetToDefaults: {
          store.removeAll()
        }
      )
    }
  }
}

// MARK: - Test Constants

struct TestConstants {
  static let testModel = "openai/gpt-oss:120b"
  static let testMessage = "Hello, how are you?"
  static let testResponse = "I'm doing well, thank you for asking!"
  
  static let availableModels = [
    "openai/gpt-oss:120b",
    "llama-2-70b-chat",
    "qwen/qwen3-70b-32k",
    "gpt-oss-3.5-turbo"
  ]
}
