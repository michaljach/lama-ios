//
//  LoadingIndicatorView.swift
//  lama
//
//  Created by Michal Jach on 14/11/2025.
//

import SwiftUI

struct LoadingIndicatorView: View {
  let text: String
  @State private var gradientOffset: CGFloat = -1
  
  var body: some View {
    HStack(spacing: 6) {
      ProgressView()
      
      Text(text)
        .foregroundStyle(.secondary)
        .overlay(
          LinearGradient(
            colors: [
              .clear,
              .primary.opacity(0.6),
              .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
          .offset(x: gradientOffset * 150)
          .mask(
            Text(text)
          )
        )
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .onAppear {
      withAnimation(
        .easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true)
      ) {
        gradientOffset = 1
      }
    }
  }
}
