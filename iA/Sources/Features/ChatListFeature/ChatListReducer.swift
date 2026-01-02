//
//  ChatListReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatList {
  @Dependency(\.googleAIService) var googleAIService
  
  @Reducer
  enum Path {
    case chat(Chat)
    case settings(Settings)
  }

  @ObservableState
  struct State: Equatable {
    var chats: IdentifiedArrayOf<Chat.State> = []
    var path = StackState<Path.State>()
    var availableModels: [String] = []
    var isLoadingModels = false
  }

  enum Action {
    case newChatButtonTapped
    case settingsButtonTapped
    case removeEmptyChats
    case initialize
    case loadModels
    case modelsLoaded([String])
    case modelsLoadError(String)
    case deleteChat(Chat.State.ID)
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .merge(
          .send(.loadModels),
          .run { send in
            await send(.newChatButtonTapped)
          }
        )
      
      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          do {
            let models = try await googleAIService.listModels()
            await send(.modelsLoaded(models))
          } catch {
            await send(.modelsLoadError(error.localizedDescription))
          }
        }
      
      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        
        // Sync models to all chats in collection
        for index in state.chats.indices {
          state.chats[index].modelPickerState.availableModels = models
        }
        
        return .none
      
      case .modelsLoadError:
        state.isLoadingModels = false
        return .none
        
      case .path(.element(id: _, action: _)):
        // Don't sync on every element action - this causes rapid updates
        // The state will be synced when the view reappears or on navigation
        return .none

      case .path(.popFrom):
        // Sync remaining elements after navigation
        for pathElement in state.path {
          if case let .chat(chat) = pathElement {
            if state.chats.contains(where: { $0.id == chat.id }) {
              state.chats[id: chat.id] = chat
            }
          }
        }
        return .none

      case .path:
        return .none

      case .removeEmptyChats:
        return .none

      case .deleteChat(let id):
        state.chats.remove(id: id)
        return .none

      case .newChatButtonTapped:
        let newChatId = UUID()
        var newChatItem = Chat.State(id: newChatId)
        newChatItem.modelPickerState.availableModels = state.availableModels
        state.chats.insert(newChatItem, at: 0)
        state.path.append(.chat(newChatItem))
        return .none

      case .settingsButtonTapped:
        state.path.append(.settings(Settings.State()))
        return .none

      case .chats:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension ChatList.Path.State: Equatable {}
