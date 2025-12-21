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
    
    init(id: UUID = UUID(), role: MessageRole, content: String, images: [UIImage] = [], reasoning: String? = nil) {
      self.id = id
      self.role = role
      self.content = content
      self.images = images
      self.reasoning = reasoning
    }
    
    // Custom Equatable implementation to ignore UIImage comparison
    static func == (lhs: State, rhs: State) -> Bool {
      lhs.id == rhs.id &&
      lhs.role == rhs.role &&
      lhs.content == rhs.content &&
      lhs.reasoning == rhs.reasoning
    }
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
