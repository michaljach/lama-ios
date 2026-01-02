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
    var sources: [WebSource] = []
    var canResend: Bool = false
    @Presents var sourcesState: Sources.State?
    
    enum MessageRole: Equatable {
      case user
      case assistant
    }
    
    static func == (lhs: State, rhs: State) -> Bool {
      return lhs.id == rhs.id &&
             lhs.role == rhs.role &&
             lhs.content == rhs.content &&
             lhs.images.count == rhs.images.count &&
             lhs.sources == rhs.sources &&
             lhs.canResend == rhs.canResend &&
             lhs.sourcesState == rhs.sourcesState
    }
  }
  
  enum Action: Equatable {
    case resend
    case showSources
    case sources(PresentationAction<Sources.Action>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .resend:
        return .none
        
      case .showSources:
        // Only show if not already showing
        guard state.sourcesState == nil else {
          return .none
        }
        state.sourcesState = Sources.State(sources: state.sources)
        return .none
        
      case .sources:
        return .none
      }
    }
    .ifLet(\.$sourcesState, action: \.sources) {
      Sources()
    }
  }
}
