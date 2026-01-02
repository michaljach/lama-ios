//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

struct ChatMessage: Equatable, Identifiable {
  let id = UUID()
  let role: String  // "user" or "assistant"
  let content: String
}

@Reducer
struct Chat {
  @Dependency(\.chatService) var chatService
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var messageInputState = MessageInput.State()
    var modelPickerState = ModelPicker.State()
    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Additional properties for compatibility with existing tests
    var loadingState: LoadingState = .idle
    var model: String = "gemini-2.5-flash"
    var isShowingWebSearchUI: Bool = false
    
    var title: String {
      if let userMessage = messages.first(where: { $0.role == "user" }) {
        let content = userMessage.content
        if content.count > 50 {
          return String(content.prefix(50)) + "..."
        }
        return content
      }
      return "New Chat"
    }
    
    var visibleMessages: [ChatMessage] {
      return messages
    }
    
    enum LoadingState: Equatable {
      case idle
      case loading
      case error(String)
    }
  }
  
  enum Action {
    case messageInput(MessageInput.Action)
    case modelPicker(ModelPicker.Action)
    case sendMessage(String)
    case messageSent(String)
    case messageReceived(String)
    case messageError(String)
    case clearError
    case modelSelected(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { (state: inout State, action: Action) -> Effect<Action> in
      switch action {
      case .messageInput(.delegate(.sendMessage)):
        let messageText = state.messageInputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return .none }
        
        state.isLoading = true
        state.loadingState = .loading
        state.errorMessage = nil
        
        let userMessage = ChatMessage(role: "user", content: messageText)
        state.messages.append(userMessage)
        
        return .run { [messages = state.messages, model = state.modelPickerState.selectedModel] send in
          await send(.messageSent(messageText))
          do {
            let response = try await chatService.sendMessage(
              messages,
              model,
              0.7,
              1024
            )
            await send(.messageReceived(response))
          } catch {
            await send(.messageError(error.localizedDescription))
          }
        }
        
      case .messageInput:
        return .none
        
      case .modelPicker:
        return .none
        
      case .sendMessage(let message):
        state.isLoading = true
        state.loadingState = .loading
        state.errorMessage = nil
        
        let userMessage = ChatMessage(role: "user", content: message)
        state.messages.append(userMessage)
        
        return .run { [messages = state.messages, model = state.modelPickerState.selectedModel] send in
          await send(.messageSent(message))
          do {
            let response = try await chatService.sendMessage(
              messages,
              model,
              0.7,
              1024
            )
            await send(.messageReceived(response))
          } catch {
            await send(.messageError(error.localizedDescription))
          }
        }
        
      case .messageSent:
        state.messageInputState.inputText = ""
        return .none
        
      case .messageReceived(let response):
        state.isLoading = false
        state.loadingState = .idle
        let assistantMessage = ChatMessage(role: "assistant", content: response)
        state.messages.append(assistantMessage)
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
    
    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
    
    Scope(state: \.modelPickerState, action: \.modelPicker) {
      ModelPicker()
    }
  }
}
