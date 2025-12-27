//
//  MessageReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct Message {
  @ObservableState
  struct State: Identifiable, Equatable {
    var id: UUID
    var role: MessageRole
    var content: String
    var images: [UIImage] = []
    var reasoning: String?
    var canResend: Bool = false
    
    init(id: UUID = UUID(), role: MessageRole, content: String, images: [UIImage] = [], reasoning: String? = nil, canResend: Bool = false) {
      self.id = id
      self.role = role
      self.content = content
      self.images = images
      self.reasoning = reasoning
      self.canResend = canResend
    }
    
    // Custom Equatable implementation to ignore UIImage comparison
    static func == (lhs: State, rhs: State) -> Bool {
      lhs.id == rhs.id &&
      lhs.role == rhs.role &&
      lhs.content == rhs.content &&
      lhs.reasoning == rhs.reasoning &&
      lhs.canResend == rhs.canResend
    }
  }
  
  enum Action: Equatable {
    case resend
  }
  
  var body: some Reducer<State, Action> {
    Reduce { (state: inout State, action: Action) -> Effect<Action> in
      switch action {
      case .resend:
        return .none
      }
    }
  }
}
