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
  @Dependency(\.groqService) var groqService
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
            let models = try await GroqService().listModels()
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
          state.chats[index].availableModels = models
        }
        
        return .none
      
      case .modelsLoadError:
        state.isLoadingModels = false
        return .none
        
      case .path(.element(id: _, action: _)):
        // Sync all changes from path to chats collection
        for pathElement in state.path {
          if case let .chat(pathChat) = pathElement {
            // Update the chats collection with the current path chat state
            if state.chats.contains(where: { $0.id == pathChat.id }) {
              state.chats[id: pathChat.id] = pathChat
            }
          }
        }
        return .none

      case .path(.popFrom):
        // Sync all pending changes before removing from navigation stack
        for pathElement in state.path {
          if case let .chat(chat) = pathElement {
            state.chats[id: chat.id] = chat
          }
        }
        // Ensure models are preserved in all chats
        for index in state.chats.indices {
          state.chats[index].availableModels = state.availableModels
        }
        // When navigating back, clean up empty chats
        return .send(.removeEmptyChats)

      case .path:
        return .none

      case .removeEmptyChats:
        // Remove chats with no visible messages
        state.chats.removeAll { chat in
          chat.messages.isEmpty
        }
        return .none

      case .deleteChat(let id):
        state.chats.remove(id: id)
        return .none

      case .newChatButtonTapped:
        let newChatId = UUID()
        var newChatItem = Chat.State(id: newChatId)
        newChatItem.availableModels = state.availableModels
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
