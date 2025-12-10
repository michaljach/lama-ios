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
  @Reducer
  enum Path {
    case chat(Chat)
    case settings(Settings)
  }

  @ObservableState
  struct State: Equatable {
    var chats: IdentifiedArrayOf<Chat.State> = []
    var path = StackState<Path.State>()
  }

  enum Action {
    case newChatButtonTapped
    case settingsButtonTapped
    case removeEmptyChats
    case initialize
    case deleteChat(Chat.State.ID)
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.newChatButtonTapped)
        }
        
      case let .path(.element(id: id, action: .chat)):
        // CRITICAL: Sync all changes from path to chats collection
        // This must happen on every chat action to preserve message history
        for (index, pathElement) in state.path.enumerated() {
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
        // When navigating back, clean up empty chats
        return .send(.removeEmptyChats)

      case .path:
        return .none

      case .removeEmptyChats:
        // Remove chats with no visible messages (excluding tool messages)
        state.chats.removeAll { chat in
          let visibleMessages = chat.messages.filter { message in
            message.role != .tool
          }
          return visibleMessages.isEmpty
        }
        return .none

      case .deleteChat(let id):
        state.chats.remove(id: id)
        return .none

      case .newChatButtonTapped:
        let newChatId = UUID()
        let newChatItem = Chat.State(id: newChatId)
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
