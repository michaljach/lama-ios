//
//  ModelPickerReducer.swift
//  lama
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ModelPicker {
  
  @ObservableState
  struct State: Equatable {
    var selectedModel: String = "models/gemini-3-flash-preview"
    var availableModels: [AIModel] = []
    var isDisabled: Bool = false
  }
  
  enum Action {
    case modelSelected(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .modelSelected(let model):
        state.selectedModel = model
        return .none
      }
    }
  }
}
