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
  @ObservableState
  struct State: Equatable {
    var groqAPIKey: String = ""
    var defaultModel: String = "openai/gpt-oss:120b"
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var webSearchEnabled: Bool = true
    var availableModels: [String] = []
    var isLoadingModels: Bool = false

    init(userDefaultsService: UserDefaultsService = .liveValue) {
      // Load from UserDefaults service
      self.groqAPIKey = userDefaultsService.getGroqAPIKey() ?? ""
      self.defaultModel = userDefaultsService.getDefaultModel()
      self.temperature = userDefaultsService.getTemperature()
      self.maxTokens = userDefaultsService.getMaxTokens()
      self.webSearchEnabled = userDefaultsService.isWebSearchEnabled()
    }
  }

  enum Action {
    case groqAPIKeyChanged(String)
    case defaultModelChanged(String)
    case temperatureChanged(Double)
    case webSearchEnabledChanged(Bool)
    case maxTokensChanged(Int)
    case resetToDefaults
    case loadModels
    case modelsLoaded([String])
    case modelsLoadFailed
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .groqAPIKeyChanged(let value):
        state.groqAPIKey = value
        userDefaultsService.setGroqAPIKey(value)
        return .none

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
      
      case .webSearchEnabledChanged(let value):
        state.webSearchEnabled = value
        userDefaultsService.setWebSearchEnabled(value)
        return .none

      case .resetToDefaults:
        userDefaultsService.resetToDefaults()
        state.groqAPIKey = userDefaultsService.getGroqAPIKey() ?? ""
        state.defaultModel = userDefaultsService.getDefaultModel()
        state.temperature = userDefaultsService.getTemperature()
        state.maxTokens = userDefaultsService.getMaxTokens()
        state.webSearchEnabled = userDefaultsService.isWebSearchEnabled()
        return .none
      
      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          let groqService = GroqService()
          do {
            let models = try await groqService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadFailed)
          }
        }
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        return .none
      
      case .modelsLoadFailed:
        state.isLoadingModels = false
        return .none
      }
    }
  }
}
