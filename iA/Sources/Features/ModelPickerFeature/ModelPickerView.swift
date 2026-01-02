//
//  ModelPickerView.swift
//  lama
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import SwiftUI

struct ModelPickerView: View {
  @Bindable var store: StoreOf<ModelPicker>

  var body: some View {
    if !store.availableModels.isEmpty {
      Menu {
        ForEach(store.availableModels, id: \.self) { model in
          Button {
            store.send(.modelSelected(model))
          } label: {
            HStack {
              Text(model)
              if model == store.selectedModel {
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
          .disabled(store.isDisabled)
        }
      } label: {
        HStack(spacing: 4) {
          Text(store.selectedModel)
            .font(.headline)
            .padding(.leading, 6)
          Image(systemName: "chevron.down")
            .font(.caption)
        }
      }
      .disabled(store.isDisabled)
      .opacity(store.isDisabled ? 0.5 : 1.0)
    }
  }
}

#Preview {
  ModelPickerView(
    store: Store(initialState: ModelPicker.State(
      selectedModel: "groq/compound",
      availableModels: ["groq/compound", "mixtral-8x7b-32768"]
    )) {
      ModelPicker()
    }
  )
}
