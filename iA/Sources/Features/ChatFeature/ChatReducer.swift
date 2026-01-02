//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation
import UIKit

// Helper struct for API communication
struct ChatMessage: Equatable, Identifiable {
  let id: UUID
  let role: String  // "user" or "assistant"
  let content: String
  let images: [UIImage]  // Attached images for multimodal support
  
  init(id: UUID, role: String, content: String, images: [UIImage] = []) {
    self.id = id
    self.role = role
    self.content = content
    self.images = images
  }
  
  static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
    return lhs.id == rhs.id &&
           lhs.role == rhs.role &&
           lhs.content == rhs.content &&
           lhs.images.count == rhs.images.count
  }
}

@Reducer
struct Chat {
  @Dependency(\.chatService) var chatService
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var messageInputState = MessageInput.State()
    var modelPickerState = ModelPicker.State()
    var messages: IdentifiedArrayOf<Message.State> = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Additional properties for compatibility with existing tests
    var loadingState: LoadingState = .idle
    var model: String = "models/gemini-3-flash-preview"
    var isShowingWebSearchUI: Bool = false
    
    var title: String {
      if let userMessage = messages.first(where: { $0.role == .user }) {
        let content = userMessage.content
        if content.count > 50 {
          return String(content.prefix(50)) + "..."
        }
        return content
      }
      return "New Chat"
    }
    
    enum LoadingState: Equatable {
      case idle
      case loading
      case webSearching
      case error(String)
    }
  }
  
  enum Action {
    case messageInput(MessageInput.Action)
    case modelPicker(ModelPicker.Action)
    case message(IdentifiedActionOf<Message>)
    case sendMessage(String)
    case messageSent(String)
    case streamToken(String, messageId: UUID)
    case streamComplete([WebSource], messageId: UUID)
    case messageError(String)
    case clearError
    case modelSelected(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { (state: inout State, action: Action) -> Effect<Action> in
      switch action {
      case .messageInput(.delegate(.sendMessage)):
        let messageText = state.messageInputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageImages = state.messageInputState.selectedImages
        guard !messageText.isEmpty || !messageImages.isEmpty else { return .none }
        
        
        let webSearchEnabled = UserDefaults.standard.bool(forKey: "webSearchEnabled")
        state.isLoading = true
        state.loadingState = webSearchEnabled ? .webSearching : .loading
        state.errorMessage = nil
        
        let userMessage = Message.State(
          id: UUID(),
          role: .user,
          content: messageText,
          images: messageImages
        )
        state.messages.append(userMessage)
        
        // Clear input after adding to messages
        state.messageInputState.inputText = ""
        state.messageInputState.selectedImages = []
        
        // Create placeholder assistant message for streaming
        let assistantMessageId = UUID()
        let assistantMessage = Message.State(
          id: assistantMessageId,
          role: .assistant,
          content: "",
          sources: []
        )
        state.messages.append(assistantMessage)
        
        // Convert to ChatMessage format for API
        let apiMessages = state.messages.filter { $0.role == .user || !$0.content.isEmpty }.map { msg in
          ChatMessage(
            id: msg.id,
            role: msg.role == .user ? "user" : "assistant",
            content: msg.content,
            images: msg.images
          )
        }
        
        return .run { [messages = apiMessages, model = state.modelPickerState.selectedModel, messageId = assistantMessageId] send in
          await send(.messageSent(messageText))
          do {
            let webSearchEnabled = UserDefaults.standard.bool(forKey: "webSearchEnabled")
            let stream = chatService.streamMessage(messages, model, 0.7, 8192, webSearchEnabled)
            
            for try await event in stream {
              switch event {
              case .token(let token):
                await send(.streamToken(token, messageId: messageId))
              case .complete(let sources):
                await send(.streamComplete(sources, messageId: messageId))
              case .error(let error):
                await send(.messageError(error))
              }
            }
          } catch {
            await send(.messageError(error.localizedDescription))
          }
        }
        
      case .messageInput:
        return .none
        
      case .modelPicker:
        return .none
        
      case .message:
        return .none
        
      case .sendMessage(let message):
        let webSearchEnabled = UserDefaults.standard.bool(forKey: "webSearchEnabled")
        state.isLoading = true
        state.loadingState = webSearchEnabled ? .webSearching : .loading
        state.errorMessage = nil
        
        let userMessage = Message.State(
          id: UUID(),
          role: .user,
          content: message
        )
        state.messages.append(userMessage)
        
        // Create placeholder assistant message for streaming
        let assistantMessageId = UUID()
        let assistantMessage = Message.State(
          id: assistantMessageId,
          role: .assistant,
          content: "",
          sources: []
        )
        state.messages.append(assistantMessage)
        
        // Convert to ChatMessage format for API (exclude empty placeholder)
        let apiMessages = state.messages.filter { $0.role == .user || !$0.content.isEmpty }.map { msg in
          ChatMessage(
            id: msg.id,
            role: msg.role == .user ? "user" : "assistant",
            content: msg.content
          )
        }
        
        return .run { [messages = apiMessages, model = state.modelPickerState.selectedModel, messageId = assistantMessageId] send in
          await send(.messageSent(message))
          do {
            let webSearchEnabled = UserDefaults.standard.bool(forKey: "webSearchEnabled")
            let stream = chatService.streamMessage(messages, model, 0.7, 8192, webSearchEnabled)
            
            for try await event in stream {
              switch event {
              case .token(let token):
                await send(.streamToken(token, messageId: messageId))
              case .complete(let sources):
                await send(.streamComplete(sources, messageId: messageId))
              case .error(let error):
                await send(.messageError(error))
              }
            }
          } catch {
            await send(.messageError(error.localizedDescription))
          }
        }
        
      case .messageSent:
        state.messageInputState.inputText = ""
        return .none
        
      case .streamToken(let token, let messageId):
        // Append token to the assistant message
        guard var message = state.messages[id: messageId] else {
          return .none
        }
        message.content += token
        state.messages[id: messageId] = message
        return .none
        
      case .streamComplete(let sources, let messageId):
        // Add sources to the assistant message and stop loading
        guard var message = state.messages[id: messageId] else {
          return .none
        }
        message.sources = sources
        state.messages[id: messageId] = message
        state.isLoading = false
        state.loadingState = .idle
        return .none
        
      case .messageError(let error):
        state.isLoading = false
        state.loadingState = .error(error)
        state.errorMessage = error
        return .none
        
      case .clearError:
        state.errorMessage = nil
        return .none
        
      case .modelSelected(let model):
        state.model = model
        state.modelPickerState.selectedModel = model
        return .none
      }
    }
    .forEach(\.messages, action: \.message) {
      Message()
    }
    
    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
    
    Scope(state: \.modelPickerState, action: \.modelPicker) {
      ModelPicker()
    }
  }
}
