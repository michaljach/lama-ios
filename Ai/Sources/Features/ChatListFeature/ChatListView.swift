//
//  ChatListView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct ChatListView: View {
  @Bindable var store: StoreOf<ChatList>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      chatListContent
    } destination: { store in
      switch store.case {
      case let .chat(store):
        ChatView(store: store)
      case let .settings(store):
        SettingsView(store: store)
      }
    }
    .onAppear {
      store.send(.initialize)
    }
  }
  
  var chatListContent: some View {
    VStack(spacing: 0) {
      if store.chats.isEmpty {
        Text("No chats yet")
          .foregroundColor(.gray)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        chatList
      }
    }
    .navigationTitle("Chats")
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { store.send(.settingsButtonTapped) }) {
          Label("Settings", systemImage: "gear")
        }
      }

      ToolbarItem(placement: .primaryAction) {
        Button(action: { store.send(.newChatButtonTapped) }) {
          Label("New Chat", systemImage: "plus")
        }
      }
    }
  }
  
  var chatList: some View {
    List {
      ForEach(store.chats) { chat in
        Button {
          store.send(.selectChat(chat.id))
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
              .font(.headline)
              .foregroundStyle(.colorForeground)
              .lineLimit(1)
            
            if let lastMessage = chat.messages.last {
              Text(lastMessage.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
          .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
          Button(role: .destructive) {
            store.send(.deleteChat(chat.id))
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
      }
    }
  }
}

#Preview {
  ChatListView(
    store: Store(initialState: ChatList.State()) {
      ChatList()
    }
  )
}
