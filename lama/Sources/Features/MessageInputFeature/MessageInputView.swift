//
//  MessageInputView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI

struct MessageInputView: View {
  @Bindable var store: StoreOf<MessageInput>
  @FocusState private var isInputFocused: Bool
  
  var body: some View {
    HStack(spacing: 12) {
      TextField("Type a message...", text: Binding(
        get: { store.inputText },
        set: { store.send(.inputTextChanged($0)) }
      ), axis: .vertical)
      .lineLimit(1...5)
      .focused($isInputFocused)
      .onSubmit {
        store.send(.submitButtonTapped)
        isInputFocused = true
      }
      
      if store.isLoading {
        Button {
          store.send(.stopButtonTapped)
        } label: {
          Image(systemName: "stop.circle.fill")
            .font(.title)
            .foregroundColor(.red)
        }
      } else {
        Button {
          store.send(.sendButtonTapped)
          isInputFocused = true
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title)
            .foregroundColor(store.isDisabled ? .gray : .blue)
        }
        .disabled(store.isDisabled)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 24)
    .background(.colorGray)
    .clipShape(Capsule())
    .padding()
    .onAppear {
      isInputFocused = true
    }
  }
}

#Preview {
  MessageInputView(
    store: Store(initialState: MessageInput.State()) {
      MessageInput()
    }
  )
}

