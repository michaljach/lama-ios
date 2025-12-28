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
            LoadingIndicatorView(text: "Thinking...")
              .id("loading")
          
          case .searchingWeb:
            LoadingIndicatorView(text: "Searching the web...")
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
          
          // Web search sources display
          if !store.webSearchSources.isEmpty && store.isShowingWebSearchUI {
            WebSearchSourcesView(sources: store.webSearchSources)
              .padding(.top, 8)
              .id("sources")
          }
        }
        .scrollTargetLayout()
      }
      .scrollDismissesKeyboard(.interactively)
      .safeAreaInset(edge: .bottom) {
        MessageInputView(
          store: store.scope(state: \.messageInputState, action: \.messageInput),
          isNewChat: store.messages.isEmpty
        )
      }
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ModelPicker(store: store, isDisabled: !store.messages.isEmpty)
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
      state.loadingState = .loading
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
          content: "Moonlit waves softly whisper secrets.",
          reasoning: "The user asked me to summarize the haiku. I need to capture the essence of the original poem - the imagery of moonlit waves and secrets - in a single concise line. The key elements are: waves, moonlight, whispers, and secrets. I'll combine these naturally."
        ),
        Message.State(
          role: .user,
          content: "What are the latest breakthroughs in quantum computing?"
        ),
        Message.State(
          role: .assistant,
          content: "Recent breakthroughs in quantum computing include Google's announcement of their Willow chip, which demonstrates significant improvements in error correction and computational capabilities. Other major developments include IBM's quantum roadmap advancements and increased investment from tech companies in quantum research.",
          reasoning: "The user is asking about recent quantum computing breakthroughs. I should search the web for the latest information to provide current and accurate details about recent announcements and developments. This is a rapidly evolving field, so web search is essential for accuracy."
        )
      ]
      state.webSearchSources = [
        WebSearchSource(
          title: "Google's Willow Quantum Chip Breakthrough",
          url: "https://blog.google/technology/ai/google-willow-quantum-chip/",
          content: "Google announces Willow, a quantum chip that demonstrates significant improvements in error correction and can perform calculations that were previously impossible."
        ),
        WebSearchSource(
          title: "IBM Quantum Computing Roadmap",
          url: "https://www.ibm.com/quantum",
          content: "IBM continues to advance quantum computing with improved qubit counts and better error correction techniques, targeting practical quantum advantage."
        ),
        WebSearchSource(
          title: "Latest Quantum Computing Developments",
          url: "https://www.nature.com/articles/quantum-computing",
          content: "Recent developments show quantum computers achieving new milestones in solving complex optimization problems and drug discovery applications."
        )
      ]
      state.isShowingWebSearchUI = true
      return state
    }()) {
      Chat()
    }
  )
}

