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
    static let groqAPIKey = "groqAPIKey"
    static let defaultModel = "defaultModel"
    static let temperature = "temperature"
    static let maxTokens = "maxTokens"
    static let webSearchEnabled = "webSearchEnabled"
  }

  // Default values
  private enum Defaults {
    nonisolated static let groqAPIKey: String? = ConfigManager.groqAPIKey
    nonisolated static let defaultModel = "groq/compound"
    nonisolated static let temperature = 0.7
    nonisolated static let maxTokens = 640
    nonisolated static let webSearchEnabled = true
  }
  
  var getGroqAPIKey: @Sendable () -> String?
  var setGroqAPIKey: @Sendable (String) -> Void
  
  var getDefaultModel: @Sendable () -> String
  var setDefaultModel: @Sendable (String) -> Void
  
  var getTemperature: @Sendable () -> Double
  var setTemperature: @Sendable (Double) -> Void
  
  var getMaxTokens: @Sendable () -> Int
  var setMaxTokens: @Sendable (Int) -> Void
  
  var isWebSearchEnabled: @Sendable () -> Bool
  var setWebSearchEnabled: @Sendable (Bool) -> Void

  var resetToDefaults: @Sendable () -> Void
}

extension UserDefaultsService: DependencyKey {
  static let liveValue = UserDefaultsService(
    getGroqAPIKey: {
      UserDefaults.standard.string(forKey: Keys.groqAPIKey) ?? Defaults.groqAPIKey
    },
    setGroqAPIKey: { value in
      UserDefaults.standard.set(value, forKey: Keys.groqAPIKey)
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
    isWebSearchEnabled: {
      let value = UserDefaults.standard.object(forKey: Keys.webSearchEnabled)
      return value == nil ? Defaults.webSearchEnabled : UserDefaults.standard.bool(forKey: Keys.webSearchEnabled)
    },
    setWebSearchEnabled: { value in
      UserDefaults.standard.set(value, forKey: Keys.webSearchEnabled)
    },
    resetToDefaults: {
      UserDefaults.standard.set(Defaults.groqAPIKey, forKey: Keys.groqAPIKey)
      UserDefaults.standard.set(Defaults.defaultModel, forKey: Keys.defaultModel)
      UserDefaults.standard.set(Defaults.temperature, forKey: Keys.temperature)
      UserDefaults.standard.set(Defaults.maxTokens, forKey: Keys.maxTokens)
      UserDefaults.standard.set(Defaults.webSearchEnabled, forKey: Keys.webSearchEnabled)
    }
  )

  static let testValue = UserDefaultsService(
    getGroqAPIKey: { Defaults.groqAPIKey },
    setGroqAPIKey: { _ in },
    getDefaultModel: { Defaults.defaultModel },
    setDefaultModel: { _ in },
    getTemperature: { Defaults.temperature },
    setTemperature: { _ in },
    getMaxTokens: { Defaults.maxTokens },
    setMaxTokens: { _ in },
    isWebSearchEnabled: { Defaults.webSearchEnabled },
    setWebSearchEnabled: { _ in },
    resetToDefaults: { }
  )
}

extension DependencyValues {
  var userDefaultsService: UserDefaultsService {
    get { self[UserDefaultsService.self] }
    set { self[UserDefaultsService.self] = newValue }
  }
}
