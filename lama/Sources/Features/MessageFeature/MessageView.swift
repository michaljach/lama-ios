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
  var store: StoreOf<Message>
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if store.role == .user {
        HStack {
          Spacer()
          
          VStack(alignment: .trailing, spacing: 8) {
            // Display images if present
            if !store.images.isEmpty {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                  ForEach(Array(store.images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                      .resizable()
                      .scaledToFill()
                      .frame(maxWidth: 200, maxHeight: 200)
                      .clipShape(RoundedRectangle(cornerRadius: 12))
                  }
                }
              }
            }
            
            // Display text if present
            if !store.content.isEmpty {
              Text(store.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.colorGray)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
            }
          }
        }
      } else {
        Markdown(store.content)
          .multilineTextAlignment(.leading)
          .textSelection(.enabled)
          .markdownTableBorderStyle(.init(color: .colorGray))
      }
    }
    .padding()
  }
}

#Preview {
  VStack {
    MessageView(
      store: Store(initialState: Message.State(
        role: .user,
        content: "Hello, how are you?",
      )) {
        Message()
      }
    )
    
    MessageView(
      store: Store(initialState: Message.State(
        role: .assistant,
        content: "I'm doing well, thank you! How can I help you today? What is up?"
      )) {
        Message()
      }
    )
  }
}
