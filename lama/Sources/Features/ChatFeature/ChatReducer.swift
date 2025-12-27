//
//  ChatReducer.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct Chat {
  @Dependency(\.groqService) var groqService
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
    var webSearchSources: [WebSearchSource] = []
    var isShowingWebSearchUI: Bool = false
    var pendingReasoning: String?
    
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
    case startChatStream([ChatMessage], enableWebSearch: Bool = true)
    case streamingResponseReceived(String)
    case streamingComplete(reason: String?)
    case streamingError(String)
    case stopGeneration
    case webSearchStarted
    case webSearchCompleted([WebSearchSource])
    case clearWebSearchUI
    case reasoningReceived(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { (state: inout State, action: Action) -> Effect<Action> in
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
            let models = try await groqService.listModels()
            await send(.modelsLoaded(models))
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
        let selectedImages = state.messageInputState.selectedImages
        let hasImages = !selectedImages.isEmpty
        
        guard !inputText.isEmpty || hasImages else {
          return .none
        }
        
        // Clear input and show loading
        state.messageInputState.inputText = ""
        state.messageInputState.selectedImages = []
        state.messageInputState.isLoading = true
        state.errorMessage = nil
        state.loadingState = .loading
        
        // Add user message with images
        let userMessageId = UUID()
        let userMessage = Message.State(
          id: userMessageId,
          role: .user,
          content: inputText,
          images: selectedImages
        )
        state.messages.append(userMessage)

        // Build messages for API - construct special multimodal format only for current user message with images
        var chatMessages: [ChatMessage] = []
        
        for message in state.messages {
          if message.id == userMessageId && hasImages && !selectedImages.isEmpty {
            // Build multimodal content block array for this user message
            var contentBlocks: [ContentBlock] = []
            
            // Add text block if there's text
            if !inputText.isEmpty {
              contentBlocks.append(ContentBlock(type: "text", text: inputText))
            }
            
            // Add image blocks in proper OpenAI format
            for image in selectedImages {
              // Resize and compress image to reduce request size
              let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))
              if let imageData = resizedImage.jpegData(compressionQuality: 0.6) {
                let base64String = imageData.base64EncodedString()
                let dataUrl = "data:image/jpeg;base64,\(base64String)"
                contentBlocks.append(ContentBlock(type: "image_url", imageUrl: dataUrl))
              }
            }
            
            chatMessages.append(ChatMessage(role: message.role, content: .array(contentBlocks)))
          } else {
            // All other messages (including previous turns) must be text-only
            chatMessages.append(ChatMessage(role: message.role, content: .text(message.content)))
          }
        }
        
        chatMessages = chatMessages.withDefaultSystemPrompt()
        
        return .send(.startChatStream(chatMessages))
        
      case .startChatStream(let chatMessages, let enableWebSearch):
        let temperature = userDefaultsService.getTemperature()
        let maxTokens = userDefaultsService.getMaxTokens()
        
        return .run { [model = state.model] send in
          do {
            // Send web search started action if enabled
            if enableWebSearch {
              await send(.webSearchStarted)
            }
            
            let stream = try await groqService.chat(
              model: model,
              messages: chatMessages,
              temperature: temperature,
              maxTokens: maxTokens,
              topP: nil,
              enableWebSearch: enableWebSearch
            )
            
            for try await response in stream {
              if Task.isCancelled {
                await send(.streamingComplete(reason: nil))
                break
              }
              
              // Extract reasoning if available
              if let reasoning = response.reasoning {
                await send(.reasoningReceived(reasoning))
              }
              
              // Extract sources from the response if available
              if let sources = response.sources, !sources.isEmpty {
                await send(.webSearchCompleted(sources))
              }
              
              // Extract content from the response
              if let message = response.message {
                var contentText = ""
                if case .text(let text) = message.content {
                  contentText = text
                }
                if !contentText.isEmpty {
                  await send(.streamingResponseReceived(contentText))
                }
              }
              
              if response.done ?? false {
                await send(.streamingComplete(reason: response.doneReason))
              }
            }
          } catch {
            await send(.streamingError(error.localizedDescription))
          }
        }
        .cancellable(id: CancelID.streaming, cancelInFlight: true)
        
      case .streamingResponseReceived(let content):
        state.errorMessage = nil
        
        // Create assistant message if it doesn't exist, otherwise append to it
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          // Append to existing assistant message
          state.messages[lastIndex].content += content
        } else {
          // Create new assistant message with pending reasoning if available
          let assistantMessage = Message.State(
            id: UUID(),
            role: .assistant,
            content: content,
            reasoning: state.pendingReasoning
          )
          state.messages.append(assistantMessage)
          state.pendingReasoning = nil
        }

        return .none
        
      case .streamingComplete(let reason):
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        return .none
        
      case .streamingError(let errorMessage):
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        state.errorMessage = errorMessage
        
        // Mark the last user message as resendable
        if let lastUserMessageIndex = state.messages.lastIndex(where: { $0.role == .user }) {
          state.messages[lastUserMessageIndex].canResend = true
        }
        
        // Remove the incomplete assistant message if it exists
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant {
          state.messages.remove(at: lastIndex)
        }
        
        return .none
        
      case .stopGeneration:
        state.loadingState = .idle
        state.messageInputState.isLoading = false
        return .cancel(id: CancelID.streaming)
        
      case .messageInput(.delegate(.stopGeneration)):
        return .send(.stopGeneration)
        
      case .messageInput:
        // Forward all other messageInput actions to the child reducer
        return .none
        
      case .messages(.element(id: let id, action: .resend)):
        // Find the resent message and rebuild the conversation
        guard let messageIndex = state.messages.firstIndex(where: { $0.id == id }) else {
          return .none
        }
        
        let resendMessage = state.messages[messageIndex]
        
        // Reset the resend button
        state.messages[messageIndex].canResend = false
        
        // Clear any previous error
        state.errorMessage = nil
        state.loadingState = .loading
        state.messageInputState.isLoading = true
        
        // Remove any assistant messages after this user message
        while state.messages.count > messageIndex + 1 {
          state.messages.remove(at: messageIndex + 1)
        }
        
        // Build messages for API up to and including the resent message
        var chatMessages: [ChatMessage] = []
        
        for message in state.messages[...messageIndex] {
          if message.id == id && !resendMessage.images.isEmpty {
            // Build multimodal content block array for this user message
            var contentBlocks: [ContentBlock] = []
            
            // Add text block if there's text
            if !resendMessage.content.isEmpty {
              contentBlocks.append(ContentBlock(type: "text", text: resendMessage.content))
            }
            
            // Add image blocks in proper OpenAI format
            for image in resendMessage.images {
              // Resize and compress image to reduce request size
              let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))
              if let imageData = resizedImage.jpegData(compressionQuality: 0.6) {
                let base64String = imageData.base64EncodedString()
                let dataUrl = "data:image/jpeg;base64,\(base64String)"
                contentBlocks.append(ContentBlock(type: "image_url", imageUrl: dataUrl))
              }
            }
            
            chatMessages.append(ChatMessage(role: message.role, content: .array(contentBlocks)))
          } else {
            // All other messages must be text-only
            chatMessages.append(ChatMessage(role: message.role, content: .text(message.content)))
          }
        }
        
        chatMessages = chatMessages.withDefaultSystemPrompt()
        
        return .send(.startChatStream(chatMessages))
        
      case .messages:
        return .none
        
      case .webSearchStarted:
        state.loadingState = .searchingWeb
        state.isShowingWebSearchUI = true
        return .none
        
      case .webSearchCompleted(let sources):
        state.webSearchSources = sources
        state.loadingState = .loading
        state.isShowingWebSearchUI = true
        return .none
        
      case .clearWebSearchUI:
        state.isShowingWebSearchUI = false
        state.webSearchSources = []
        return .none
        
      case .reasoningReceived(let reasoning):
        state.pendingReasoning = reasoning
        // Also update the last assistant message if it exists and doesn't have reasoning yet
        if let lastIndex = state.messages.indices.last,
           state.messages[lastIndex].role == .assistant,
           state.messages[lastIndex].reasoning == nil {
          state.messages[lastIndex].reasoning = reasoning
        }
        return .none
      }
    }
    Scope(state: \.messageInputState, action: \.messageInput) {
      MessageInput()
    }
  }
}

// MARK: - UIImage Extension

extension UIImage {
  /// Resize image to fit within the specified size while maintaining aspect ratio
  func resized(to size: CGSize) -> UIImage {
    let aspectRatio = self.size.width / self.size.height
    let targetSize: CGSize
    
    if aspectRatio > 1 {
      // Landscape or square
      targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
    } else {
      // Portrait
      targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
    }
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    
    return resizedImage
  }
}
