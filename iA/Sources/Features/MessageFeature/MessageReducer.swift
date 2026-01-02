//
//  MessageReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Message {
  @ObservableState
  struct State: Identifiable, Equatable {
    var id: UUID
    var role: MessageRole
    var content: String
    var canResend: Bool = false
    
    enum MessageRole: Equatable {
      case user
      case assistant
    }
  }
  
  enum Action: Equatable {
    case resend
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .resend:
        return .none
      }
    }
  }
}
