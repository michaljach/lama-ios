//
//  ChatView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI
import MarkdownUI

struct ChatView: View {
  @Bindable var store: StoreOf<Chat>
  
  var body: some View {
    VStack(spacing: 0) {
      // Error banner
      if let errorMessage = store.errorMessage {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
              .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
              Text("Error")
                .font(.headline)
                .foregroundColor(.primary)
              
              Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: { store.send(.clearError) }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .font(.title3)
            }
          }
          .padding(16)
          .background(Color.orange.opacity(0.1))
          .cornerRadius(12)
          .padding(.horizontal, 16)
          .padding(.top, 8)
          .padding(.bottom, 8)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
      }
      
      ScrollViewReader { scrollProxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEachStore(
              store.scope(state: \.messages, action: \.message)
            ) { messageStore in
              MessageView(store: messageStore)
            }
            
            // Loading indicator
            if store.isLoading {
              HStack(spacing: 8) {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle())
                  .scaleEffect(0.8)
                
                if store.loadingState == .webSearching {
                  Text("Searching the web...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                } else {
                  Text("Thinking...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .transition(.opacity)
              .id("loading-indicator")
            }
          }
          .scrollTargetLayout()
          .onChange(of: store.messages.count) { _, newCount in
            // Scroll to bottom when new message arrives
            if let lastMessage = store.messages.last {
              scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
          }
          .onChange(of: store.isLoading) { _, isLoading in
            // Scroll to loading indicator when it appears
            if isLoading {
              scrollProxy.scrollTo("loading-indicator", anchor: .bottom)
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
      var state = Chat.State(
        id: UUID()
      )
      return state
    }()) {
      Chat()
    }
  )
}
