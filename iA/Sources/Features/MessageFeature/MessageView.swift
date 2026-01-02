//
//  MessageView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI
import MarkdownUI

struct MessageView: View {
  @Bindable var store: StoreOf<Message>
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if store.role == .user {
        HStack {
          Spacer()
          VStack(alignment: .trailing, spacing: 8) {
            // Display images if present
            if !store.images.isEmpty {
              ForEach(Array(store.images.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image)
                  .resizable()
                  .scaledToFit()
                  .frame(maxWidth: 200)
                  .cornerRadius(12)
              }
            }
            
            // Display text if present
            if !store.content.isEmpty {
              Text(store.content)
                .textSelection(.enabled)
                .foregroundColor(.colorForeground)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.colorGray)
                .clipShape(Capsule())
            }
          }
        }
      } else {
        VStack(alignment: .leading, spacing: 12) {
          Markdown(store.content)
            .textSelection(.enabled)
            .markdownTextStyle(\.text) {
              ForegroundColor(.colorForeground)
            }
            .markdownTextStyle(\.code) {
              FontFamilyVariant(.monospaced)
              BackgroundColor(Color.colorForeground.opacity(0.08))
            }
            .markdownBlockStyle(\.codeBlock) { configuration in
              configuration.label
                .padding()
                .background(Color.colorForeground.opacity(0.08))
                .cornerRadius(8)
            }
          
          // Compact sources bar
          if !store.sources.isEmpty {
            SourcesBarView(sources: store.sources) {
              store.send(.showSources)
            }
          }
        }
        .padding(.vertical, 8)
      }
    }
    .padding(.horizontal, 16)
    .sheet(item: $store.scope(state: \.sourcesState, action: \.sources)) { sourcesStore in
      SourcesDetailSheet(store: sourcesStore)
    }
  }
}

#Preview {
  VStack {
    MessageView(
      store: Store(initialState: Message.State(
        id: UUID(),
        role: .user,
        content: "Hello, how are you?"
      )) {
        Message()
      }
    )
    
    MessageView(
      store: Store(initialState: Message.State(
        id: UUID(),
        role: .assistant,
        content: "I'm doing well, thank you for asking! How can I help you today?",
        sources: [
          WebSource(title: "Example Source", url: "https://example.com"),
          WebSource(title: "Another Source", url: "https://apple.com"),
          WebSource(title: "Third Source", url: "https://google.com")
        ]
      )) {
        Message()
      }
    )
  }
}
