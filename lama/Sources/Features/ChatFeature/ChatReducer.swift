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
    var scrollPosition: String?
  // Tracks how many times we've auto-continued to finish a cut-off message
  var autoFinishAttempts: Int = 0

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
    case streamingComplete(reason: String?)
    case streamingError(String)
    case stopGeneration
    case scrollPositionChanged(String?)
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
        
        // Debug: Print messages being sent to API
        print("🔵 Sending \(chatMessages.count) messages to API:")
        for (index, msg) in chatMessages.enumerated() {
          let preview = msg.content.prefix(50)
          print("  \(index + 1). [\(msg.role)] \(preview)...")
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
  state.autoFinishAttempts = 0
        // Force a new scroll event by clearing, then sending an update
        state.scrollPosition = nil
        
        // Also trigger scroll to bottom right after appending the assistant placeholder
        // Prepare generation options from settings
        let temperature = userDefaultsService.getTemperature()
        let maxTokens = userDefaultsService.getMaxTokens()
        let options = ChatOptions(temperature: temperature, numPredict: maxTokens)

        return .merge(
          .send(.scrollPositionChanged("bottom")),
          .run { [model = state.model, options] send in
            do {
              let stream = try await ollamaService.chat(
                model: model,
                messages: chatMessages,
                options: options
              )
              for try await response in stream {
                if Task.isCancelled {
                  await send(.streamingComplete(reason: nil))
                  break
                }
                if let messageContent = response.message?.content {
                  await send(.streamingResponseReceived(messageContent))
                }
                if response.done == true {
                  await send(.streamingComplete(reason: response.doneReason))
                  break
                }
              }
            } catch {
              if !Task.isCancelled {
                await send(.streamingError(error.localizedDescription))
              } else {
                await send(.streamingComplete(reason: nil))
              }
            }
          }
          .cancellable(id: CancelID.streaming)
        )
        
      case .streamingResponseReceived(let content):
        // Update the last message (assistant message) with streaming content
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          state.messages[lastIndex].content += content
          // Scroll to bottom periodically during streaming to reduce frequency
          if state.messages[lastIndex].content.count % 80 < content.count {
            // Force a new scroll event by toggling the binding value
            state.scrollPosition = nil
            return .send(.scrollPositionChanged("bottom"))
          }
        }
        return .none
        
      case .streamingComplete(let reason):
        // Decide if we should auto-continue to finish a sentence or code block
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          let text = state.messages[lastIndex].content
          let needsMore = Self.needsContinuation(text: text)
          let hitLength = (reason == "length")
          if (needsMore || hitLength), state.autoFinishAttempts < 2 {
            state.autoFinishAttempts += 1
            // Keep loading indicators during auto-continue
            state.isLoading = true
            state.messageInputState.isLoading = true
            // Prepare messages for a follow-up "continue" without altering visible chat history
            let baseMessages = state.messages.map { ChatMessage(role: $0.role, content: $0.content) }
            let continueMessages = baseMessages + [
              ChatMessage(role: .user, content: "Please continue the previous answer and finish the last sentence or code block.")
            ]
            let temperature = userDefaultsService.getTemperature()
            let maxTokens = userDefaultsService.getMaxTokens()
            let options = ChatOptions(temperature: temperature, numPredict: maxTokens)
            return .merge(
              .send(.scrollPositionChanged("bottom")),
              .run { [model = state.model] send in
                do {
                  let stream = try await ollamaService.chat(
                    model: model,
                    messages: continueMessages,
                    options: options
                  )
                  for try await response in stream {
                    if Task.isCancelled {
                      await send(.streamingComplete(reason: nil))
                      break
                    }
                    if let messageContent = response.message?.content {
                      await send(.streamingResponseReceived(messageContent))
                    }
                    if response.done == true {
                      await send(.streamingComplete(reason: response.doneReason))
                      break
                    }
                  }
                } catch {
                  if !Task.isCancelled {
                    await send(.streamingError(error.localizedDescription))
                  } else {
                    await send(.streamingComplete(reason: nil))
                  }
                }
              }
              .cancellable(id: CancelID.streaming)
            )
          }
        }
        // No auto-continue, finalize loading state
        state.isLoading = false
        state.messageInputState.isLoading = false
        state.scrollPosition = nil
        return .send(.scrollPositionChanged("bottom"))
        
        
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
        state.autoFinishAttempts = 0
        return .cancel(id: CancelID.streaming)
        
      case .messageInput(.delegate(.stopGeneration)):
        return .send(.stopGeneration)
        
      case .messageInput:
        return .none

      case .messages:
        return .none

      case .scrollPositionChanged(let position):
        state.scrollPosition = position
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

// MARK: - Helpers

extension Chat {
  /// Heuristic to decide if the assistant message likely ended mid-thought
  static func needsContinuation(text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    // If code fences are unbalanced, continue
    let fenceCount = trimmed.components(separatedBy: "```" ).count - 1
    if fenceCount % 2 != 0 { return true }
    // If ends with common sentence terminators, we're good
    if let last = trimmed.last, "。.!?…\"”’)]>}\n".contains(last) {
      return false
    }
    // If last line seems truncated (no ending punctuation and not a heading or list), continue
    if let lastLine = trimmed.split(separator: "\n").last {
      let line = lastLine.trimmingCharacters(in: .whitespaces)
      // If it's a list/heading or code fence line, don't force continue
      if line.hasPrefix("#") || line.hasPrefix("-") || line.hasPrefix("*") || line.hasPrefix("`") {
        return false
      }
    }
    return true
  }
}
