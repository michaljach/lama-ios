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
    ZStack {
      VStack(spacing: 0) {
        // Messages List
        ScrollViewReader { proxy in
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
                  .padding()
                  .id("loading")
              
              case .searchingWeb:
                LoadingIndicatorView(text: "Searching the web...")
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
              
              // Web search sources display
              if !store.webSearchSources.isEmpty && store.isShowingWebSearchUI {
                WebSearchSourcesView(sources: store.webSearchSources)
                  .padding(.vertical, 8)
                  .id("sources")
              }

              Color.clear
                .frame(height: 100)
                .id("bottom")
            }
            .scrollTargetLayout()
          }
          .scrollDismissesKeyboard(.interactively)
          .defaultScrollAnchor(.bottom)
          .onChange(of: store.scrollPosition) { _, newValue in
            if let position = newValue {
              withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(position, anchor: .bottom)
              }
            }
          }
        }
      }
      
      VStack(spacing: 0) {
        Spacer()
        
        MessageInputView(
          store: store.scope(state: \.messageInputState, action: \.messageInput)
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
        )
      ]
      state.webSearchSources = [
        WebSearchSource(
          title: "The Power of Haiku Poetry",
          url: "https://www.poetryfoundation.org/poems/haiku",
          content: "Haiku is a traditional form of Japanese poetry consisting of three lines with a 5-7-5 syllable pattern."
        ),
        WebSearchSource(
          title: "Ocean Poetry Classics",
          url: "https://www.literarydevices.com/ocean-poetry",
          content: "Ocean poetry has inspired writers for centuries with its themes of mystery, power, and tranquility."
        )
      ]
      state.isShowingWebSearchUI = true
      return state
    }()) {
      Chat()
    }
  )
}

