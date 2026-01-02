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
    var defaultModel: String = "models/gemini-3-flash-preview"
    var temperature: Double = 0.7
    var maxTokens: Int = 1024
    var availableModels: [AIModel] = []
    var isLoadingModels: Bool = false
    var googleAIAPIKey: String = ""
    var webSearchEnabled: Bool = true

    init(userDefaultsService: UserDefaultsService = .liveValue) {
      // Load from UserDefaults service
      self.defaultModel = userDefaultsService.getDefaultModel()
      self.temperature = userDefaultsService.getTemperature()
      self.maxTokens = userDefaultsService.getMaxTokens()
      self.googleAIAPIKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
      self.webSearchEnabled = UserDefaults.standard.object(forKey: "webSearchEnabled") != nil 
        ? UserDefaults.standard.bool(forKey: "webSearchEnabled") 
        : true
    }
  }

  enum Action {
    case defaultModelChanged(String)
    case temperatureChanged(Double)
    case maxTokensChanged(Int)
    case resetToDefaults
    case loadModels
    case modelsLoaded([AIModel])
    case modelsLoadFailed
    case googleAIAPIKeyChanged(String)
    case webSearchToggled(Bool)
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
        return .run { send in
          do {
            let models = try await googleAIService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadFailed)
          }
        }
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        // If current model is not in the list, use the first one
        if !models.contains(where: { $0.name == state.defaultModel }), let firstModel = models.first {
          state.defaultModel = firstModel.name
        }
        return .none
      
      case .modelsLoadFailed:
        state.isLoadingModels = false
        return .none
      
      case .googleAIAPIKeyChanged(let key):
        state.googleAIAPIKey = key
        UserDefaults.standard.set(key, forKey: "googleAIAPIKey")
        return .none
      
      case .webSearchToggled(let enabled):
        state.webSearchEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "webSearchEnabled")
        return .none
      }
    }
  }
}
