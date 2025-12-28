//
//  ReasoningView.swift
//  lama
//
//  Created by Michal Jach on 21/12/2025.
//

import SwiftUI
import MarkdownUI

struct ReasoningView: View {
  let reasoning: String
  @State private var isShowingSheet = false
  
  var previewText: String {
    let stripped = stripMarkdown(reasoning)
    let lines = stripped.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
    let preview = lines.prefix(2).joined(separator: "\n")
    if lines.count > 2 {
      return preview + "..."
    }
    return preview
  }
  
  private func stripMarkdown(_ text: String) -> String {
    var result = text
    // Remove bold markers
    result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
    // Remove italic markers
    result = result.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
    result = result.replacingOccurrences(of: "_(.+?)_", with: "$1", options: .regularExpression)
    // Remove code markers
    result = result.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
    // Remove headers
    result = result.replacingOccurrences(of: "^#+\\s+", with: "", options: .regularExpression)
    // Remove links [text](url)
    result = result.replacingOccurrences(of: "\\[(.+?)\\]\\(.+?\\)", with: "$1", options: .regularExpression)
    return result
  }
  
  var body: some View {
    Button(action: {
      isShowingSheet = true
    }) {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Image(systemName: "sparkles")
            .font(.caption)
          
          Text("Reasoning")
            .font(.caption)
            .fontWeight(.semibold)
        }
        
        Text(previewText)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(10)
      .background(Color.colorGray)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .foregroundStyle(.colorForeground)
    }
    .sheet(isPresented: $isShowingSheet) {
      ReasoningSheetView(reasoning: reasoning, isPresented: $isShowingSheet)
    }
  }
}

struct ReasoningSheetView: View {
  let reasoning: String
  @Binding var isPresented: Bool
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Markdown(reasoning)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .markdownTableBorderStyle(.init(color: .colorGray))
        }
        .padding()
      }
      .navigationTitle("Reasoning")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { isPresented = false }) {
            Image(systemName: "xmark")
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }
}

#Preview {
  ReasoningView(reasoning: "The user is asking about web search. I need to search for the latest information about web search and then provide a comprehensive answer with sources. Let me break down the steps: 1) Understand what web search entails, 2) Research current best practices, 3) Gather relevant sources, 4) Compile comprehensive response.")
}
