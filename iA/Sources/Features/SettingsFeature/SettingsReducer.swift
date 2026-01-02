//
//  SettingsReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Settings {
  @Dependency(\.userDefaultsService) var userDefaultsService
  @Dependency(\.googleAIService) var googleAIService
  
  @ObservableState
  struct State: Equatable {
    var defaultModel: String = "gemini-2.5-flash"
    var temperature: Double = 0.7
    var maxTokens: Int = 1024
    var availableModels: [String] = []
    var isLoadingModels: Bool = false
    var googleAIAPIKey: String = ""

    init(userDefaultsService: UserDefaultsService = .liveValue) {
      // Load from UserDefaults service
      self.defaultModel = userDefaultsService.getDefaultModel()
      self.temperature = userDefaultsService.getTemperature()
      self.maxTokens = userDefaultsService.getMaxTokens()
      self.googleAIAPIKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
    }
  }

  enum Action {
    case defaultModelChanged(String)
    case temperatureChanged(Double)
    case maxTokensChanged(Int)
    case resetToDefaults
    case loadModels
    case modelsLoaded([String])
    case modelsLoadFailed
    case googleAIAPIKeyChanged(String)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .defaultModelChanged(let value):
        state.defaultModel = value
        userDefaultsService.setDefaultModel(value)
        return .none

      case .temperatureChanged(let value):
        state.temperature = value
        userDefaultsService.setTemperature(value)
        return .none

      case .maxTokensChanged(let value):
        state.maxTokens = value
        userDefaultsService.setMaxTokens(value)
        return .none

      case .resetToDefaults:
        userDefaultsService.resetToDefaults()
        state.defaultModel = userDefaultsService.getDefaultModel()
        state.temperature = userDefaultsService.getTemperature()
        state.maxTokens = userDefaultsService.getMaxTokens()
        return .none
      
      case .loadModels:
        state.isLoadingModels = true
        return .none
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        return .none
      
      case .modelsLoadFailed:
        state.isLoadingModels = false
        return .none
      
      case .googleAIAPIKeyChanged(let key):
        state.googleAIAPIKey = key
        UserDefaults.standard.set(key, forKey: "googleAIAPIKey")
        return .none
      }
    }
  }
}
