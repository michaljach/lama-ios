//
//  ChatView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct ChatView: View {
  @Bindable var store: StoreOf<Chat>
  
  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { scrollProxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            if store.messages.isEmpty {
              VStack {
                Text("No messages yet")
                  .foregroundColor(.gray)
                Text("Start a conversation")
                  .foregroundColor(.gray)
                  .font(.caption)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding()
             } else {
              ForEach(store.messages) { message in
                VStack {
                  HStack(alignment: .top, spacing: 12) {
                    if message.role == "assistant" {
                      Circle()
                        .fill(Color.colorBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                          Text("AI")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                      Text(message.content)
                        .textSelection(.enabled)
                        .foregroundColor(message.role == "user" ? .white : .colorForeground)
                        .lineLimit(nil)
                    }
                    
                    if message.role == "user" {
                      Spacer()
                    }
                  }
                  .padding(.vertical, 12)
                  .padding(.horizontal, 16)
                  .background(
                    message.role == "user"
                      ? Color.colorBlue
                      : Color.colorForeground.opacity(0.08)
                  )
                  .cornerRadius(12)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 4)
                }
                .id(message.id)
              }
            }
          }
          .scrollTargetLayout()
          .onChange(of: store.messages.count) { _, newCount in
            // Scroll to bottom when new message arrives
            if let lastMessage = store.messages.last {
              scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .safeAreaInset(edge: .bottom) {
        MessageInputView(
          store: store.scope(
            state: \.messageInputState,
            action: \.messageInput
          )
        )
      }
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ModelPickerView(
          store: store.scope(
            state: \.modelPickerState,
            action: \.modelPicker
          )
        )
      }
    }
  }
}


#Preview {
  ChatView(
    store: Store(initialState: {
      var state = Chat.State(id: UUID())
      return state
    }()) {
      Chat()
    }
  )
}

