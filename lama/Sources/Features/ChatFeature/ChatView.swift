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
      ScrollViewReader { proxy in
        ZStack(alignment: .bottomTrailing) {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
              ForEach(store.scope(state: \.messages, action: \.messages)) { store in
                MessageView(store: store)
                  .id(store.id)
              }

              if store.isLoading {
                HStack {
                  ProgressView()
                    .scaleEffect(0.8)
                  Text("Thinking...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .id("loading")
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
                .onAppear {
                  store.send(.bottomAppeared)
                }
                .onDisappear {
                  store.send(.bottomDisappeared)
                }
            }
            .padding()
          }
          .scrollDismissesKeyboard(.interactively)
          .onChange(of: store.messages.count) { oldCount, newCount in
            if !store.isUserScrolling || store.isAtBottom {
              withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
              }
            }
          }
          .onChange(of: store.isLoading) { _, isLoading in
            if isLoading && (!store.isUserScrolling || store.isAtBottom) {
              withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
              }
            }
          }
          .onChange(of: store.messages.last?.content) { _, _ in
            if !store.isUserScrolling || store.isAtBottom {
              proxy.scrollTo("bottom", anchor: .bottom)
            }
          }

          // Floating scroll to bottom button
          if store.isUserScrolling && !store.isAtBottom {
            Button {
              store.send(.scrollToBottomTapped)
              withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
              }
            } label: {
              Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white, .blue)
                .shadow(radius: 4)
            }
            .padding()
            .transition(.scale.combined(with: .opacity))
          }
        }
      }
      
      // Input
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
    store: Store(initialState: Chat.State(id: UUID())) {
      Chat()
    }
  )
}

