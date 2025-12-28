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
      Group {
        if store.chats.isEmpty {
          NoChatsMessage()
        } else {
          List {
            ForEach(store.chats, id: \.id) { chat in
              NavigationLink(state: ChatList.Path.State.chat(chat)) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(chat.title)
                    .font(.headline)
                  let visibleMessageCount = chat.messages.count
                  if visibleMessageCount > 0 {
                    Text("\(visibleMessageCount) message\(visibleMessageCount == 1 ? "" : "s")")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
                .padding(.vertical, 4)
              }
            }
            .onDelete { indexSet in
              for index in indexSet {
                let chat = store.chats[store.chats.index(store.chats.startIndex, offsetBy: index)]
                store.send(.deleteChat(chat.id))
              }
            }
          }
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
}

#Preview {
  ChatListView(
    store: Store(initialState: ChatList.State()) {
      ChatList()
    }
  )
}

