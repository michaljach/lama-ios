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
    case deleteChat(Chat.State.ID)
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .path(.element(id: id, action: .chat(chatAction))):
        // Sync changes from path chat to the chats collection
        if let pathChat = state.path[id: id]?.chat {
          state.chats[id: pathChat.id] = pathChat
        }
        return .none

      case .path(.popFrom):
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
        state.chats.append(newChatItem)
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
