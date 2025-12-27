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
        HStack(alignment: .bottom, spacing: 8) {
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
              VStack(alignment: .trailing, spacing: 8) {
                Text(store.content)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 12)
                  .background(Color.colorGray)
                  .clipShape(RoundedRectangle(cornerRadius: 24))
                  .textSelection(.enabled)
                  .multilineTextAlignment(.leading)
                
                // Resend button for failed messages
                if store.canResend {
                  Button(action: {
                    store.send(.resend)
                  }) {
                    HStack {
                      Text("Resend")
                      
                      Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                    }
                    .foregroundColor(.colorForeground)
                  }
                }
              }
            }
          }
        }
      } else {
        VStack(alignment: .leading, spacing: 12) {
          // Display reasoning if available
          if let reasoning = store.reasoning, !reasoning.isEmpty {
            ReasoningView(reasoning: reasoning)
              .padding(.top, 8)
          }
          
          // Display main content
          Markdown(store.content)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .markdownTableBorderStyle(.init(color: .colorGray))
        }
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
    
    MessageView(
      store: Store(initialState: Message.State(
        role: .user,
        content: "Can you help me with this error?",
        canResend: true
      )) {
        Message()
      }
    )
  }
}
