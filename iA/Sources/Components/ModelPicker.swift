//
//  ModelPicker.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct ModelPicker: View {
  let store: StoreOf<Chat>
  let isDisabled: Bool

  var body: some View {
    if !store.availableModels.isEmpty {
      Menu {
        ForEach(store.availableModels, id: \.self) { model in
          Button {
            store.send(.modelSelected(model))
          } label: {
            HStack {
              Text(model)
              if model == store.model {
                Image(systemName: "checkmark")
              }
              
              // Show capabilities
              HStack(spacing: 4) {
                if model.contains("compound") {
                  Image(systemName: "globe.americas.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
                if model.contains("gpt-oss") {
                  Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
                if model.contains("llama-4-scout") {
                  Image(systemName: "photo.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                }
              }
            }
          }
          .disabled(isDisabled)
        }
      } label: {
        HStack(spacing: 4) {
          Text(store.model)
            .font(.headline)
            .padding(.leading, 6)
          Image(systemName: "chevron.down")
            .font(.caption)
        }
      }
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.5 : 1.0)
    }
  }
}
