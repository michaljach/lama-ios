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
    VStack(alignment: .leading) {
      if store.role == .user {
        HStack {
          Spacer()

          Text(store.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
      } else {
        Markdown(store.content)
          .textSelection(.enabled)
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
        content: "Hello, how are you?"
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
