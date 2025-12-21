//
//  ReasoningView.swift
//  lama
//
//  Created by Michal Jach on 21/12/2025.
//

import SwiftUI

struct ReasoningView: View {
  let reasoning: String
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.2)) {
          isExpanded.toggle()
        }
      }) {
        HStack {
          Image(systemName: "sparkles")
            .font(.caption)
            .foregroundStyle(.orange)
          
          Text("Reasoning")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
          
          Spacer()
          
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      
      if isExpanded {
        Text(reasoning)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(nil)
          .multilineTextAlignment(.leading)
          .padding(10)
          .background(Color.colorGray.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }
}

#Preview {
  ReasoningView(reasoning: "The user is asking about web search. I need to search for the latest information about web search and then provide a comprehensive answer with sources. Let me break down the steps: 1) Understand what web search entails, 2) Research current best practices, 3) Gather relevant sources, 4) Compile comprehensive response.")
}
