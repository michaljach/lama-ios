//
//  MessageInputReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct MessageInput {
  @ObservableState
  struct State: Equatable {
    var inputText: String = ""
    var isLoading: Bool = false
    var selectedImages: [UIImage] = []
    var showImagePicker: Bool = false
    
    init(inputText: String = "", isLoading: Bool = false, selectedImages: [UIImage] = [], showImagePicker: Bool = false) {
      self.inputText = inputText
      self.isLoading = isLoading
      self.selectedImages = selectedImages
      self.showImagePicker = showImagePicker
    }
  }
  
  enum Action: Equatable {
    case inputTextChanged(String)
    case sendButtonTapped
    case submitButtonTapped
    case stopButtonTapped
    case imagePickerTapped
    case imagesSelected([UIImage])
    case removeImage(Int)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case sendMessage
      case stopGeneration
    }
    
    static func == (lhs: Action, rhs: Action) -> Bool {
      switch (lhs, rhs) {
      case (.inputTextChanged(let a), .inputTextChanged(let b)):
        return a == b
      case (.imagePickerTapped, .imagePickerTapped):
        return true
      case (.sendButtonTapped, .sendButtonTapped):
        return true
      case (.submitButtonTapped, .submitButtonTapped):
        return true
      case (.stopButtonTapped, .stopButtonTapped):
        return true
      case (.imagesSelected, .imagesSelected):
        return true  // UIImage doesn't conform to Equatable, so we can't compare
      case (.removeImage(let a), .removeImage(let b)):
        return a == b
      case (.delegate(let a), .delegate(let b)):
        return a == b
      default:
        return false
      }
    }
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .inputTextChanged(let text):
        state.inputText = text
        return .none
        
      case .sendButtonTapped:
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !state.selectedImages.isEmpty else {
          return .none
        }
        return .send(.delegate(.sendMessage))
        
      case .submitButtonTapped:
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !state.selectedImages.isEmpty else {
          return .none
        }
        return .send(.delegate(.sendMessage))
        
      case .stopButtonTapped:
        return .send(.delegate(.stopGeneration))
        
      case .imagePickerTapped:
        state.showImagePicker = true
        return .none
        
      case .imagesSelected(let images):
        state.selectedImages.append(contentsOf: images)
        state.showImagePicker = false
        return .none
        
      case .removeImage(let index):
        if index < state.selectedImages.count {
          state.selectedImages.remove(at: index)
        }
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

