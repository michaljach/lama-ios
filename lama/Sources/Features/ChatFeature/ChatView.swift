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
      // Messages List
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(store.scope(state: \.visibleMessages, action: \.messages)) { store in
            MessageView(store: store)
              .id(store.id)
          }

          // Loading indicator based on state
          switch store.loadingState {
          case .loading:
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Thinking...")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .id("loading")
            
          case .searchingWeb:
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Searching the web...")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .id("searching")
            
          case .idle:
            EmptyView()
          }

          if let error = store.errorMessage {
            Text("Error: \(error)")
              .font(.caption)
              .foregroundColor(.red)
              .padding(.horizontal)
          }

          Color.clear
            .frame(height: 1)
            .id("bottom")
        }
        .scrollTargetLayout()
      }
      .scrollDismissesKeyboard(.interactively)
      .defaultScrollAnchor(.bottom)
      
      MessageInputView(
        store: store.scope(state: \.messageInputState, action: \.messageInput)
      )
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("PrivateGPT")
      }
      
      ToolbarItem(placement: .topBarTrailing) {
        ModelPicker(store: store)
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
    .onDisappear {
      store.send(.onDisappear)
    }
  }
}


#Preview {
  ChatView(
    store: Store(initialState: {
      var state = Chat.State(id: UUID())
      state.messages = [
        Message.State(
          role: .user,
          content: "Write a short haiku about the sea."
        ),
        Message.State(
          role: .assistant,
          content: "Blue waves whisper low\nMoonlight dances on the foam\nNight keeps its secrets."
        ),
        Message.State(
          role: .user,
          content: "Now summarize it in one line."
        ),
        Message.State(
          role: .assistant,
          content: "Moonlit waves softly whisper secrets."
        )
      ]
      return state
    }()) {
      Chat()
    }
  )
}

