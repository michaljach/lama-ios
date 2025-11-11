//
//  UserDefaultsService.swift
//  lama
//
//  Created by Michal Jach on 10/11/2025.
//

import Foundation
import ComposableArchitecture

/// Service for managing user defaults/preferences
struct UserDefaultsService {
  // Keys
  private enum Keys {
    static let ollamaEndpoint = "ollamaEndpoint"
    static let defaultModel = "defaultModel"
    static let temperature = "temperature"
    static let maxTokens = "maxTokens"
  }
  
  // Default values
  private enum Defaults {
    static let ollamaEndpoint = "https://ollama.com"
    static let defaultModel = "gpt-oss:120b"
    static let temperature = 0.7
    static let maxTokens = 2048
    static let authToken = "760999c692364c0a843c1fbc5d6f491b.c_EfP3NyyWUpPGI3OYjqNr9S"
  }
  
  var getOllamaEndpoint: @Sendable () -> String
  var setOllamaEndpoint: @Sendable (String) -> Void
  
  var getDefaultModel: @Sendable () -> String
  var setDefaultModel: @Sendable (String) -> Void
  
  var getTemperature: @Sendable () -> Double
  var setTemperature: @Sendable (Double) -> Void
  
  var getMaxTokens: @Sendable () -> Int
  var setMaxTokens: @Sendable (Int) -> Void
  
  var getAuthToken: @Sendable () -> String?
  
  var resetToDefaults: @Sendable () -> Void
}

extension UserDefaultsService: DependencyKey {
  static let liveValue = UserDefaultsService(
    getOllamaEndpoint: {
      UserDefaults.standard.string(forKey: Keys.ollamaEndpoint) ?? Defaults.ollamaEndpoint
    },
    setOllamaEndpoint: { value in
      UserDefaults.standard.set(value, forKey: Keys.ollamaEndpoint)
    },
    getDefaultModel: {
      UserDefaults.standard.string(forKey: Keys.defaultModel) ?? Defaults.defaultModel
    },
    setDefaultModel: { value in
      UserDefaults.standard.set(value, forKey: Keys.defaultModel)
    },
    getTemperature: {
      let value = UserDefaults.standard.double(forKey: Keys.temperature)
      return value == 0 ? Defaults.temperature : value
    },
    setTemperature: { value in
      UserDefaults.standard.set(value, forKey: Keys.temperature)
    },
    getMaxTokens: {
      let value = UserDefaults.standard.integer(forKey: Keys.maxTokens)
      return value > 0 ? value : Defaults.maxTokens
    },
    setMaxTokens: { value in
      UserDefaults.standard.set(value, forKey: Keys.maxTokens)
    },
    getAuthToken: {
      Defaults.authToken
    },
    resetToDefaults: {
      UserDefaults.standard.set(Defaults.ollamaEndpoint, forKey: Keys.ollamaEndpoint)
      UserDefaults.standard.set(Defaults.defaultModel, forKey: Keys.defaultModel)
      UserDefaults.standard.set(Defaults.temperature, forKey: Keys.temperature)
      UserDefaults.standard.set(Defaults.maxTokens, forKey: Keys.maxTokens)
    }
  )
  
  static let testValue = UserDefaultsService(
    getOllamaEndpoint: { Defaults.ollamaEndpoint },
    setOllamaEndpoint: { _ in },
    getDefaultModel: { Defaults.defaultModel },
    setDefaultModel: { _ in },
    getTemperature: { Defaults.temperature },
    setTemperature: { _ in },
    getMaxTokens: { Defaults.maxTokens },
    setMaxTokens: { _ in },
    getAuthToken: { Defaults.authToken },
    resetToDefaults: { }
  )
}

extension DependencyValues {
  var userDefaultsService: UserDefaultsService {
    get { self[UserDefaultsService.self] }
    set { self[UserDefaultsService.self] = newValue }
  }
}
