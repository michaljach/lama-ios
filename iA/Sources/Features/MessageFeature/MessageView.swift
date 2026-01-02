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
    HStack(alignment: .top, spacing: 12) {
      if store.role == .assistant {
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
        
        // Message content
        Text(store.content)
          .textSelection(.enabled)
          .foregroundColor(store.role == .user ? .white : .colorForeground)
          .lineLimit(nil)
      }
      
      if store.role == .user {
        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      store.role == .user
        ? Color.colorBlue
        : Color.colorForeground.opacity(0.08)
    )
    .cornerRadius(12)
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
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
        content: "I'm doing well, thank you for asking! How can I help you today?"
      )) {
        Message()
      }
    )
  }
}
