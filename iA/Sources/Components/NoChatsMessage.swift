//
//  NoChatsMessage.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import SwiftUI

struct NoChatsMessage: View {
  var body: some View {
    VStack {
      Spacer()
      Text("No chats available")
        .foregroundColor(.secondary)
        .font(.body)
      Spacer()
    }
  }
}

#Preview {
  NoChatsMessage()
}

