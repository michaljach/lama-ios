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
      ZStack {
        if store.chats.isEmpty {
          NoChatsMessage()
        } else {
          chatListContent
        }
      }
      .navigationTitle("Chats")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { store.send(.settingsButtonTapped) }) {
            Image(systemName: "gear")
          }
        }

        ToolbarItem(placement: .primaryAction) {
          Button(action: { store.send(.newChatButtonTapped) }) {
            Image(systemName: "plus")
          }
        }
      }
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
    List {
      ForEach(Array(store.chats.enumerated()), id: \.element.id) { _, chat in
        NavigationLink(state: ChatList.Path.State.chat(chat)) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Chat")
              .font(.headline)
          }
          .padding(.vertical, 4)
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

