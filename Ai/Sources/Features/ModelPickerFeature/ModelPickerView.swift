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
      #if os(macOS)
      // Mac-friendly picker with dropdown
      Picker("Model", selection: Binding(
        get: { store.selectedModel },
        set: { store.send(.modelSelected($0)) }
      )) {
        ForEach(store.availableModels, id: \.id) { model in
          HStack {
            Text(model.friendlyName)
              .lineLimit(1)
              .truncationMode(.tail)
            
            // Show capabilities
            if model.name.contains("compound") {
              Image(systemName: "globe.americas.fill")
                .font(.caption2)
                .foregroundStyle(.blue)
            }
            if model.name.contains("gpt-oss") {
              Image(systemName: "sparkles")
                .font(.caption2)
                .foregroundStyle(.orange)
            }
            if model.name.contains("llama-4-scout") {
              Image(systemName: "photo.fill")
                .font(.caption2)
                .foregroundStyle(.green)
            }
          }
          .tag(model.name)
        }
      }
      .pickerStyle(.menu)
      .disabled(store.isDisabled)
      .opacity(store.isDisabled ? 0.5 : 1.0)
      #else
      // iOS/iPadOS menu button
      Menu {
        ForEach(store.availableModels, id: \.id) { model in
          Button {
            store.send(.modelSelected(model.name))
          } label: {
            HStack {
              Text(model.friendlyName)
                .lineLimit(1)
                .truncationMode(.tail)
              if model.name == store.selectedModel {
                Image(systemName: "checkmark")
              }
              
              // Show capabilities
              HStack(spacing: 4) {
                if model.name.contains("compound") {
                  Image(systemName: "globe.americas.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                }
                if model.name.contains("gpt-oss") {
                  Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
                if model.name.contains("llama-4-scout") {
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
          Text(store.availableModels.first(where: { $0.name == store.selectedModel })?.friendlyName ?? store.selectedModel)
            .font(.headline)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.leading, 6)
          Image(systemName: "chevron.down")
            .font(.caption)
        }
      }
      .disabled(store.isDisabled)
      .opacity(store.isDisabled ? 0.5 : 1.0)
      #endif
    }
  }
}

#Preview {
  ModelPickerView(
    store: Store(initialState: ModelPicker.State(
      selectedModel: "groq/compound",
      availableModels: [
        AIModel(name: "groq/compound", displayName: "Compound"),
        AIModel(name: "mixtral-8x7b-32768", displayName: "Mixtral 8x7B")
      ]
    )) {
      ModelPicker()
    }
  )
}
