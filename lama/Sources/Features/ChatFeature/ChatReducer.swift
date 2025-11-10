//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Chat {
  @Dependency(\.ollamaService) var ollamaService
  @Dependency(\.userDefaultsService) var userDefaultsService
  
  nonisolated enum CancelID: Hashable, Sendable {
    case streaming
  }
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var model: String
    var availableModels: [String] = []
    var isLoadingModels: Bool = false
    var errorMessage: String?
    var isLoading: Bool = false
    var messages: IdentifiedArrayOf<Message.State> = []
    var messageInputState = MessageInput.State()
    var isUserScrolling: Bool = false
    var isAtBottom: Bool = true

    init(id: UUID, userDefaultsService: UserDefaultsService = .liveValue) {
      self.id = id
      // Load default model from settings
      self.model = userDefaultsService.getDefaultModel()
    }

    /// Computed property for chat title based on first user message
    var title: String {
      // Find the first user message
      if let firstUserMessage = messages.first(where: { $0.role == .user }) {
        let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        // Limit to first 50 characters
        if content.count > 50 {
          return String(content.prefix(50)) + "..."
        }
        return content.isEmpty ? "New Chat" : content
      }
      return "New Chat"
    }
  }

  enum Action {
    case messages(IdentifiedActionOf<Message>)
    case messageInput(MessageInput.Action)
    case onAppear
    case onDisappear
    case modelSelected(String)
    case loadModels
    case modelsLoaded([String])
    case modelsLoadError(String)
    case streamingResponseReceived(String)
    case streamingComplete
    case streamingError(String)
    case stopGeneration
    case userDidScroll
    case scrollToBottomTapped
    case bottomAppeared
    case bottomDisappeared
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.loadModels)
        
      case .onDisappear:
        // Stop generation when navigating away
        if state.isLoading {
          return .send(.stopGeneration)
        }
        return .none

      case .loadModels:
        state.isLoadingModels = true
        return .run { send in
          do {
            let response = try await ollamaService.listModels()
            let modelNames = response.models.map { $0.name }
            await send(.modelsLoaded(modelNames))
          } catch {
            await send(.modelsLoadError(error.localizedDescription))
          }
        }

      case .modelsLoaded(let models):
        state.isLoadingModels = false
        state.availableModels = models
        // If current model is not in the list and there are models, select the first one
        if !models.isEmpty && !models.contains(state.model) {
          state.model = models[0]
        }
        return .none

      case .modelsLoadError(let error):
        state.isLoadingModels = false
        // Silently fail - keep the default model
        return .none

      case .modelSelected(let model):
        state.model = model
        return .none

      case .messageInput(.delegate(.sendMessage)):
        let inputText = state.messageInputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputText.isEmpty else {
          return .none
        }

        // Clear input
        state.messageInputState.inputText = ""
        state.messageInputState.isLoading = true
        state.errorMessage = nil

        // Add user message
        let userMessageId = UUID()
        let userMessage = Message.State(
          id: userMessageId,
          role: .user,
          content: inputText
        )
        state.messages.append(userMessage)
        
        // Convert existing messages (including the user message we just added) to ChatMessage format for Ollama
        // We'll add the assistant placeholder after converting
        let chatMessages = state.messages.map { message in
          ChatMessage(role: message.role, content: message.content)
        }
        
        // Create assistant message placeholder for streaming
        let assistantMessageId = UUID()
        let assistantMessage = Message.State(
          id: assistantMessageId,
          role: .assistant,
          content: ""
        )
        state.messages.append(assistantMessage)
        state.isLoading = true
        
        // Start streaming request
        return .run { [model = state.model] send in
          do {
            let stream = try await ollamaService.chat(
              model: model,
              messages: chatMessages
            )
            
            for try await response in stream {
              // Check if cancellation was requested
              if Task.isCancelled {
                await send(.streamingComplete)
                break
              }
              
              if let messageContent = response.message?.content {
                await send(.streamingResponseReceived(messageContent))
              }
              
              if response.done == true {
                await send(.streamingComplete)
                break
              }
            }
          } catch {
            // Only send error if not cancelled
            if !Task.isCancelled {
              await send(.streamingError(error.localizedDescription))
            } else {
              await send(.streamingComplete)
            }
          }
        }
        .cancellable(id: CancelID.streaming)
        
      case .streamingResponseReceived(let content):
        // Update the last message (assistant message) with streaming content
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          state.messages[lastIndex].content += content
        }
        return .none
        
      case .streamingComplete:
        state.isLoading = false
        state.messageInputState.isLoading = false
        return .none
        
      case .streamingError(let errorMessage):
        state.isLoading = false
        state.messageInputState.isLoading = false
        state.errorMessage = errorMessage
        // Remove the empty assistant message if there was an error
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant,
           state.messages[lastIndex].content.isEmpty {
          state.messages.remove(at: lastIndex)
        }
        return .none
        
      case .stopGeneration:
        state.isLoading = false
        state.messageInputState.isLoading = false
        return .cancel(id: CancelID.streaming)
        
      case .messageInput(.delegate(.stopGeneration)):
        return .send(.stopGeneration)
        
      case .messageInput:
        return .none

      case .messages:
        return .none

      case .userDidScroll:
        state.isUserScrolling = true
        return .none

      case .scrollToBottomTapped:
        state.isUserScrolling = false
        state.isAtBottom = true
        return .none

      case .bottomAppeared:
        state.isAtBottom = true
        return .none

      case .bottomDisappeared:
        state.isAtBottom = false
        if !state.isUserScrolling {
          return .send(.userDidScroll)
        }
        return .none
      }
    }
    .forEach(\.messages, action: \.messages) {
      Message()
    }

    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
  }
}
