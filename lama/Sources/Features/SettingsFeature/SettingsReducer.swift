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
    var ollamaEndpoint: String = "http://192.168.68.54:11434"
    var defaultModel: String = "gemma3:4b"
    var temperature: Double = 0.7
    var maxTokens: Int = 2048

    init(userDefaultsService: UserDefaultsService = .liveValue) {
      // Load from UserDefaults service
      self.ollamaEndpoint = userDefaultsService.getOllamaEndpoint()
      self.defaultModel = userDefaultsService.getDefaultModel()
      self.temperature = userDefaultsService.getTemperature()
      self.maxTokens = userDefaultsService.getMaxTokens()
    }
  }

  enum Action {
    case ollamaEndpointChanged(String)
    case defaultModelChanged(String)
    case temperatureChanged(Double)
    case maxTokensChanged(Int)
    case resetToDefaults
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .ollamaEndpointChanged(let value):
        state.ollamaEndpoint = value
        userDefaultsService.setOllamaEndpoint(value)
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

      case .resetToDefaults:
        state.ollamaEndpoint = "http://192.168.68.54:11434"
        state.defaultModel = "gemma3:4b"
        state.temperature = 0.7
        state.maxTokens = 2048
        userDefaultsService.resetToDefaults()
        return .none
      }
    }
  }
}
