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

  var body: some View {
    if store.isLoadingModels {
      HStack {
        Text("Loading models...")
          .font(.headline)
        ProgressView()
          .scaleEffect(0.8)
      }
    } else if !store.availableModels.isEmpty {
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
            }
          }
        }
      } label: {
        HStack(spacing: 4) {
          Text(store.model)
            .font(.headline)
          Image(systemName: "chevron.down")
            .font(.caption)
        }
      }
    } else {
      Text(store.model)
        .font(.headline)
    }
  }
}
