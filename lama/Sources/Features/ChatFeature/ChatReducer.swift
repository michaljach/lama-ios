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
  
  enum LoadingState: Equatable {
    case idle
    case loading
    case searchingWeb
  }
  
  @ObservableState
  struct State: Equatable, Identifiable {
    let id: UUID
    var model: String
    var availableModels: [String] = []
    var isLoadingModels: Bool = false
    var errorMessage: String?
    var loadingState: LoadingState = .idle
    var messages: IdentifiedArrayOf<Message.State> = []
    var visibleMessages: IdentifiedArrayOf<Message.State> {
      self.messages.filter({ [.assistant, .system, .user].contains($0.role) })
    }
    var messageInputState = MessageInput.State()
    var scrollPosition: String?
    
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
    case performWebSearch(String)
    case webSearchComplete(String)
    case startChatStream([ChatMessage])
    case streamingResponseReceived(String)
    case streamingComplete(reason: String?)
    case streamingError(String)
    case toolCallsReceived([ToolCall])
    case executeToolCalls([ToolCall])
    case toolCallCompleted(String, String) // toolName, result
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
        if state.loadingState != .idle {
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
        
      case .modelsLoadError:
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
        
        // Clear input and show loading
        state.messageInputState.inputText = ""
        state.errorMessage = nil
        state.loadingState = .loading
        state.messageInputState.isLoading = true
        state.messageInputState.isBlocked = true
        
        // Add user message
        let userMessageId = UUID()
        let userMessage = Message.State(
          id: userMessageId,
          role: .user,
          content: inputText
        )
        state.messages.append(userMessage)

        // Convert existing messages (including the user message we just added) to ChatMessage format for Ollama
        let chatMessages = state.messages.map { message in
          ChatMessage(role: message.role, content: message.content)
        }.withDefaultSystemPrompt()

        // Force a new scroll event by clearing, then sending an update
        state.scrollPosition = nil
        
        return .merge(
          .send(.scrollPositionChanged("bottom")),
          .send(.performWebSearch(inputText))
        )
        
      case .performWebSearch(let query):
        state.loadingState = .searchingWeb
        return .run { [model = state.model] send in
          do {
            let searchResults = try await ollamaService.webSearch(query: query)
            let resultsText = searchResults.results.map { result in
              "Title: \(result.title)\nURL: \(result.url)\n\(result.content)"
            }.joined(separator: "\n\n")
            
            await send(.webSearchComplete(resultsText))
          } catch {
            // If web search fails, continue without it
            await send(.webSearchComplete(""))
          }
        }
        
      case .webSearchComplete(let searchResults):
        // Get all messages and include search results in context
        var messagesForChat = state.messages.map { message in
          ChatMessage(role: message.role, content: message.content)
        }.withDefaultSystemPrompt()
        
        // Insert web search results as a system message before the model processes
        if !searchResults.isEmpty {
          let searchContextMessage = ChatMessage(
            role: .system,
            content: "Here are recent web search results to inform your response:\n\n\(searchResults)"
          )
          // Insert after system prompt but before other messages
          if !messagesForChat.isEmpty && messagesForChat[0].role == .system {
            messagesForChat.insert(searchContextMessage, at: 1)
          } else {
            messagesForChat.insert(searchContextMessage, at: 0)
          }
        }
        
        return .send(.startChatStream(messagesForChat))
        
      case .startChatStream(let chatMessages):
        let temperature = userDefaultsService.getTemperature()
        let maxTokens = userDefaultsService.getMaxTokens()
        let options = ChatOptions(
          temperature: temperature,
          numPredict: maxTokens,
          stop: []  // Don't stop early - let the model complete naturally up to max tokens
        )
        
        return .run { [model = state.model] send in
          do {
            let stream = try await ollamaService.chat(
              model: model,
              messages: chatMessages,
              options: options,
              tools: nil
            )
            for try await response in stream {
              if Task.isCancelled {
                await send(.streamingComplete(reason: nil))
                break
              }
              
              // Check for tool calls
              if let toolCalls = response.message?.toolCalls, !toolCalls.isEmpty {
                await send(.toolCallsReceived(toolCalls))
              }
              
              if let messageContent = response.message?.content, !messageContent.isEmpty {
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
        
      case .streamingResponseReceived(let content):
        // Only process if we have actual content
        guard !content.isEmpty else {
          return .none
        }

        // Create assistant message if it doesn't exist, otherwise append to it
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          // Append to existing assistant message
          state.messages[lastIndex].content += content
        } else {
          // Create new assistant message with this content
          let assistantMessage = Message.State(
            id: UUID(),
            role: .assistant,
            content: content
          )
          state.messages.append(assistantMessage)
        }

        // Keep loading state active during streaming - only hide on completion

        return .none
        
      case .streamingComplete(let reason):
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        state.messageInputState.isBlocked = false

        state.scrollPosition = nil
        return .send(.scrollPositionChanged("bottom"))
        
        
      case .streamingError(let errorMessage):
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        state.messageInputState.isBlocked = false
        state.errorMessage = errorMessage
        return .none
        
      case .toolCallsReceived(let toolCalls):
        // Switch to web searching state
        state.loadingState = .searchingWeb
        return .send(.executeToolCalls(toolCalls))
        
      case .executeToolCalls(let toolCalls):
        return .run { [model = state.model] send in
          for toolCall in toolCalls {
            if toolCall.function.name == "web_search" {
              do {
                // Parse the arguments - handle both string and object formats
                let argumentsData = toolCall.function.arguments.data(using: .utf8) ?? Data()
                
                guard let arguments = try? JSONSerialization.jsonObject(with: argumentsData) as? [String: Any],
                      let query = arguments["query"] as? String else {
                  await send(.streamingError("Invalid web search query format"))
                  continue
                }
                
                let searchResults = try await ollamaService.webSearch(query: query)
                
                // Format the results as a string
                let resultsText = searchResults.results.map { result in
                  "Title: \(result.title)\nURL: \(result.url)\n\(result.content)"
                }.joined(separator: "\n\n")
                
                await send(.toolCallCompleted("web_search", resultsText))
              } catch {
                // Turn off web search indicator and show error
                await send(.streamingError("Web search failed: \(error.localizedDescription)"))
              }
            }
          }
        }
        
      case .toolCallCompleted(let toolName, let result):
        // Back to regular loading - content will arrive next
        state.loadingState = .loading

        // Add the tool result as a tool message (hidden in UI)
        let toolMessage = Message.State(
          id: UUID(),
          role: .tool,
          content: "Search results:\n\n\(result)"
        )
        state.messages.append(toolMessage)

        // Convert messages including the tool result for the API call
        let chatMessages = state.messages.map { message in
          ChatMessage(role: message.role, content: message.content)
        }.withDefaultSystemPrompt()
        
        return .send(.startChatStream(chatMessages))
        
      case .stopGeneration:
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        state.messageInputState.isBlocked = false
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
