//
//  MessageInputView.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

struct MessageInputView: View {
  @Bindable var store: StoreOf<MessageInput>
  @FocusState private var isInputFocused: Bool
  @State private var selectedPhotoPickerItem: PhotosPickerItem?
  
  var body: some View {
    VStack(spacing: 8) {
      // Image attachments
      if !store.selectedImages.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Array(store.selectedImages.enumerated()), id: \.offset) { index, image in
              ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 80, height: 80)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button {
                  store.send(.removeImage(index))
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(4)
                }
              }
            }
          }
          .padding(.horizontal)
        }
      }
      
      // Input area
      HStack(spacing: 12) {
        VStack {
          PhotosPicker(
            selection: $selectedPhotoPickerItem,
            matching: .images,
            label: {
              Image(systemName: "plus")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.colorBlue)
                .padding(16)
                .apply { view in
                  if #available(iOS 26.0, *) {
                    view.glassEffect(.regular.interactive())
                  } else {
                    view
                  }
                }
            }
          )
          .onChange(of: selectedPhotoPickerItem) { _, newItem in
            Task {
              if let newItem = newItem,
                 let imageData = try await newItem.loadTransferable(type: Data.self),
                 let uiImage = UIImage(data: imageData) {
                store.send(.imagesSelected([uiImage]))
                selectedPhotoPickerItem = nil
              }
            }
          }
        }
        
        HStack(spacing: 12) {
          TextField("Type a message...", text: Binding(
            get: { store.inputText },
            set: { newValue in
              store.send(.inputTextChanged(newValue))
            }
          ))
          .focused($isInputFocused)
          .disabled(store.isLoading)
          .submitLabel(.send)
          .padding(14)
          .onSubmit {
            store.send(.submitButtonTapped)
            isInputFocused = false
          }
          
          if store.isLoading {
            Button {
              store.send(.stopButtonTapped)
            } label: {
              Image(systemName: "stop.fill")
                .resizable()
                .frame(width: 12, height: 12)
                .padding(12)
                .foregroundStyle(Color.colorForegroundInverse)
                .background(Circle().fill(Color.colorBlue))
            }
          } else {
            Button {
              store.send(.sendButtonTapped)
              isInputFocused = false
            } label: {
              Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 14, height: 14)
                .padding(10)
                .foregroundStyle(Color.colorForegroundInverse)
                .background(Circle().fill(Color.colorBlue))
            }
            .disabled(store.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
          }
        }
        .padding(.trailing, 8)
        .apply { view in
          if #available(iOS 26.0, *) {
            view.glassEffect(.regular.interactive())
          } else {
            view
          }
        }
      }
      .padding()
    }
    .onAppear {
      isInputFocused = true
    }
  }
}

extension View {
  func apply<V: View>(@ViewBuilder transform: (Self) -> V) -> V {
    transform(self)
  }
}

#Preview {
  MessageInputView(
    store: Store(initialState: MessageInput.State(
      isLoading: true
    )) {
      MessageInput()
    }
  )
}

