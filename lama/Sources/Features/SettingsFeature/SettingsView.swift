//
//  SettingsView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  let store: StoreOf<Settings>

  var body: some View {
    Form {
      Section {
        TextField("Ollama Endpoint", text: Binding(
          get: { store.ollamaEndpoint },
          set: { store.send(.ollamaEndpointChanged($0)) }
        ))
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .keyboardType(.URL)

        TextField("Default Model", text: Binding(
          get: { store.defaultModel },
          set: { store.send(.defaultModelChanged($0)) }
        ))
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      } header: {
        Text("Connection")
      } footer: {
        Text("Enter the URL of your Ollama server (e.g., http://192.168.1.100:11434)")
      }

      Section {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Temperature")
            Spacer()
            Text(String(format: "%.2f", store.temperature))
              .foregroundStyle(.secondary)
          }
          Slider(value: Binding(
            get: { store.temperature },
            set: { store.send(.temperatureChanged($0)) }
          ), in: 0...2, step: 0.1)
        }

        Stepper(
          "Max Tokens: \(store.maxTokens)",
          value: Binding(
            get: { store.maxTokens },
            set: { store.send(.maxTokensChanged($0)) }
          ),
          in: 128...8192,
          step: 128
        )
      } header: {
        Text("Generation Parameters")
      } footer: {
        Text("Temperature controls randomness (0 = deterministic, 2 = very creative). Max tokens limits response length.")
      }

      Section {
        Toggle(isOn: Binding(
          get: { store.webSearchEnabled },
          set: { store.send(.webSearchEnabledChanged($0)) }
        )) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Web Search")
            Text("Allow the model to search the web for current information")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } header: {
        Text("Features")
      } footer: {
        Text("When enabled, the model can search the internet to provide up-to-date information. Requires an Ollama API key.")
      }

      Section {
        Button(role: .destructive) {
          store.send(.resetToDefaults)
        } label: {
          HStack {
            Spacer()
            Text("Reset to Defaults")
            Spacer()
          }
        }
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    SettingsView(
      store: Store(initialState: Settings.State()) {
        Settings()
      }
    )
  }
}
