//
//  SourcesReducer.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Sources {
  @ObservableState
  struct State: Equatable {
    var sources: [WebSource]
  }
  
  enum Action: Equatable {
    case sourceSelected(String) // URL string
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sourceSelected:
        // URL opening is handled by Link in the view
        return .none
      }
    }
  }
}
