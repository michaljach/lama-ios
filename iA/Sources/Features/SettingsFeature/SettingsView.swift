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
        SecureField("Groq API Key", text: Binding(
          get: { store.groqAPIKey },
          set: { store.send(.groqAPIKeyChanged($0)) }
        ))
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()

        if store.isLoadingModels {
          HStack {
            Text("Default Model")
            Spacer()
            ProgressView()
              .scaleEffect(0.8, anchor: .center)
          }
        } else if store.availableModels.isEmpty {
          Picker("Default Model", selection: Binding(
            get: { store.defaultModel },
            set: { store.send(.defaultModelChanged($0)) }
          )) {
            Text("No models available").tag("")
          }
          .disabled(true)
        } else {
          Picker("Default Model", selection: Binding(
            get: { store.defaultModel },
            set: { store.send(.defaultModelChanged($0)) }
          )) {
            ForEach(store.availableModels, id: \.self) { model in
              Text(model).tag(model)
            }
          }
        }
      } header: {
        Text("Groq API")
      } footer: {
        Text("Get your API key from https://console.groq.com/keys")
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
        Toggle("Enable Web Search", isOn: Binding(
          get: { store.webSearchEnabled },
          set: { store.send(.webSearchEnabledChanged($0)) }
        ))
      } header: {
        Text("Web Search")
      } footer: {
        Text("Allow the AI to search the web for current information when answering questions.")
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
    .onAppear {
      store.send(.loadModels)
    }
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
