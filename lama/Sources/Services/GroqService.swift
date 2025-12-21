//
//  GroqService.swift
//  lama
//
//  Created by Michal Jach on 20/12/2025.
//

import Foundation

/// Service for interacting with the Groq API
actor GroqService {
  private let urlSession: URLSession
  private let userDefaultsService: UserDefaultsService
  private let baseURL = "https://api.groq.com/openai/v1"
  
  /// Initialize the Groq service
  /// - Parameters:
  ///   - urlSession: Optional custom URLSession for testing
  ///   - userDefaultsService: Service for accessing user defaults
  init(urlSession: URLSession = .shared, userDefaultsService: UserDefaultsService = .liveValue) {
    self.urlSession = urlSession
    self.userDefaultsService = userDefaultsService
  }
  
  /// Get the API key from settings
  private var apiKey: String? {
    userDefaultsService.getGroqAPIKey()
  }
  
  /// Add authorization header to request
  private func addAuthorizationHeader(to request: inout URLRequest) throws {
    guard let apiKey = apiKey, !apiKey.isEmpty else {
      throw GroqError.missingAPIKey
    }
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  }
  
  // MARK: - Chat Completion
  
  /// Send a chat message and get a streaming response
  /// - Parameters:
  ///   - model: The model name to use (e.g., "mixtral-8x7b-32768")
  ///   - messages: Array of chat messages
  ///   - temperature: Temperature for randomness (0.0-2.0)
  ///   - maxTokens: Maximum tokens to generate
  ///   - topP: Top-p sampling parameter
  ///   - enableWebSearch: Whether to enable web search (uses Compound models)
  /// - Returns: AsyncThrowingStream of ChatResponse chunks
  func chat(
    model: String,
    messages: [ChatMessage],
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    topP: Double? = nil,
    enableWebSearch: Bool = false
  ) async throws -> AsyncThrowingStream<ChatResponse, Error> {
    // Determine which model to use
    var modelToUse = model
    
    // Check if any message contains images
    let hasImages = messages.contains { message in
      if case .array(let blocks) = message.content {
        return blocks.contains { $0.type == "image_url" }
      }
      return false
    }
    
    // Use appropriate model based on content
    if hasImages {
      // Use vision model for image requests
      modelToUse = "meta-llama/llama-4-scout-17b-16e-instruct"
    } else if enableWebSearch {
      modelToUse = "groq/compound"
    }
    
    let tools: [GroqTool]? = nil
    
    let groqRequest = GroqChatRequest(
      model: modelToUse,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: true,
      tools: tools
    )
    
    return try await performStreamingRequest(request: groqRequest)
  }
  
  /// Send a chat message and get a complete response
  /// - Parameters:
  ///   - model: The model name to use
  ///   - messages: Array of chat messages
  ///   - temperature: Temperature for randomness
  ///   - maxTokens: Maximum tokens to generate
  ///   - topP: Top-p sampling parameter
  ///   - enableWebSearch: Whether to enable web search (uses Compound models)
  /// - Returns: Complete ChatResponse
  func chatComplete(
    model: String,
    messages: [ChatMessage],
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    topP: Double? = nil,
    enableWebSearch: Bool = false
  ) async throws -> ChatResponse {
    // Check if any message contains images
    let hasImages = messages.contains { message in
      if case .array(let blocks) = message.content {
        return blocks.contains { $0.type == "image_url" }
      }
      return false
    }
    
    // Determine which model to use
    var modelToUse = model
    if hasImages {
      // Use vision model for image requests
      modelToUse = "meta-llama/llama-4-scout-17b-16e-instruct"
    } else if enableWebSearch {
      modelToUse = "groq/compound"
    }
    
    let tools: [GroqTool]? = nil  // Compound models handle tools natively, no need to specify
    
    let groqRequest = GroqChatRequest(
      model: modelToUse,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: false,
      tools: tools
    )
    
    return try await performRequest(request: groqRequest)
  }
  
  // MARK: - Models
  
  /// List available Groq models
  /// - Returns: Array of available model names
  func listModels() async throws -> [String] {
    guard let url = URL(string: "\(baseURL)/models") else {
      throw GroqError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"
    try addAuthorizationHeader(to: &urlRequest)
    
    do {
      let (data, response) = try await urlSession.data(for: urlRequest)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw GroqError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        if let errorResponse = try? JSONDecoder().decode(GroqErrorResponse.self, from: data) {
          throw GroqError.apiError(errorResponse.error?.message ?? "Unknown error")
        }
        throw GroqError.httpError(httpResponse.statusCode)
      }
      
      let modelsResponse = try JSONDecoder().decode(GroqModelsResponse.self, from: data)
      return modelsResponse.data.map { $0.id }
    } catch let error as GroqError {
      throw error
    } catch {
      throw GroqError.networkError(error)
    }
  }
  
  // MARK: - Private Helpers
  
  private func performRequest(request: GroqChatRequest) async throws -> ChatResponse {
    guard let url = URL(string: "\(baseURL)/chat/completions") else {
      throw GroqError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    try addAuthorizationHeader(to: &urlRequest)
    
    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw GroqError.encodingError(error)
    }
    
    do {
      let (data, response) = try await urlSession.data(for: urlRequest)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw GroqError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        if let errorResponse = try? JSONDecoder().decode(GroqErrorResponse.self, from: data) {
          throw GroqError.apiError(errorResponse.error?.message ?? "Unknown error")
        }
        throw GroqError.httpError(httpResponse.statusCode)
      }
      
      let groqResponse = try JSONDecoder().decode(GroqChatResponse.self, from: data)
      return convertGroqResponseToChatResponse(groqResponse)
    } catch let error as GroqError {
      throw error
    } catch {
      throw GroqError.networkError(error)
    }
  }
  
  private func performStreamingRequest(request: GroqChatRequest) async throws -> AsyncThrowingStream<ChatResponse, Error> {
    guard let url = URL(string: "\(baseURL)/chat/completions") else {
      throw GroqError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    try addAuthorizationHeader(to: &urlRequest)
    
    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw GroqError.encodingError(error)
    }
    
    return AsyncThrowingStream { continuation in
      Task {
        do {
          let (bytes, response) = try await urlSession.bytes(for: urlRequest)
          
          guard let httpResponse = response as? HTTPURLResponse else {
            continuation.finish(throwing: GroqError.invalidResponse)
            return
          }
          
          guard (200...299).contains(httpResponse.statusCode) else {
            var errorData = Data()
            for try await byte in bytes {
              errorData.append(byte)
            }
            if let errorResponse = try? JSONDecoder().decode(GroqErrorResponse.self, from: errorData) {
              continuation.finish(throwing: GroqError.apiError(errorResponse.error?.message ?? "Unknown error"))
            } else {
              continuation.finish(throwing: GroqError.httpError(httpResponse.statusCode))
            }
            return
          }
          
          var lineBuffer = [UInt8]()
          
          for try await byte in bytes {
            lineBuffer.append(byte)
            
            // Check for complete JSON objects (newline-delimited, SSE format)
            if byte == 0x0A { // newline character
              if !lineBuffer.isEmpty {
                let line = Data(lineBuffer.dropLast()) // Remove newline
                if !line.isEmpty {
                  let lineString = String(data: line, encoding: .utf8) ?? ""
                  
                  // Skip SSE prefix "data: "
                  if lineString.hasPrefix("data: ") {
                    let jsonString = String(lineString.dropFirst(6))
                    
                    // Skip [DONE] message
                    if jsonString == "[DONE]" {
                      lineBuffer.removeAll()
                      continue
                    }
                    
                    if let jsonData = jsonString.data(using: .utf8) {
                      do {
                        let groqResponse = try JSONDecoder().decode(GroqChatResponse.self, from: jsonData)
                        let chatResponse = convertGroqResponseToChatResponse(groqResponse)
                        continuation.yield(chatResponse)
                      } catch {
                        continuation.finish(throwing: GroqError.decodingError(error))
                        return
                      }
                    }
                  }
                }
                lineBuffer.removeAll()
              }
            }
          }
          
          continuation.finish()
        } catch let error as GroqError {
          continuation.finish(throwing: error)
        } catch {
          continuation.finish(throwing: GroqError.networkError(error))
        }
      }
    }
  }
  
  private func convertGroqResponseToChatResponse(_ groqResponse: GroqChatResponse) -> ChatResponse {
    let choice = groqResponse.choices.first
    let messageContentStr = choice?.message?.content ?? choice?.delta?.content ?? ""
    
    // Extract tool calls from either message or delta
    let toolCalls = choice?.message?.tool_calls ?? choice?.delta?.tool_calls
    
    // Extract web search sources from executed_tools (Groq Compound models)
    let executedTools = choice?.message?.executed_tools ?? choice?.delta?.executed_tools
    let sources = extractWebSearchSources(from: executedTools)
    
    // Extract reasoning if available
    let reasoning = choice?.message?.reasoning
    
    // Convert string content to MessageContent (keep it simple for streaming)
    let message = ChatMessage(role: .assistant, content: messageContentStr, toolCalls: toolCalls)
    
    return ChatResponse(
      model: groqResponse.model,
      createdAt: groqResponse.created.map { String($0) },
      message: message,
      done: choice?.finishReason != nil,
      doneReason: choice?.finishReason,
      totalDuration: nil,
      loadDuration: nil,
      promptEvalCount: groqResponse.usage?.promptTokens.map { Int32($0) },
      promptEvalDuration: nil,
      evalCount: groqResponse.usage?.completionTokens.map { Int32($0) },
      evalDuration: nil,
      sources: sources,
      reasoning: reasoning
    )
  }
  
  private func extractWebSearchSources(from executedTools: [ExecutedTool]?) -> [WebSearchSource]? {
    guard let executedTools = executedTools else { return nil }
    
    var sources: [WebSearchSource] = []
    
    for tool in executedTools {
      guard let searchResultsContainer = tool.search_results,
            let searchResults = searchResultsContainer.results else { continue }
      
      for result in searchResults {
        let title = result.title ?? "Untitled"
        let url = result.url ?? ""
        let content = result.content ?? ""
        
        if !title.isEmpty && !url.isEmpty {
          sources.append(WebSearchSource(title: title, url: url, content: content))
        }
      }
    }
    
    return sources.isEmpty ? nil : sources
  }
  
  // MARK: - Web Search
  
  /// Enable web search by using Groq's Compound models
  /// Web search is automatically handled by the Compound models (groq/compound, groq/compound-mini)
  /// No manual web search implementation needed - the API handles it server-side
  
  // To use web search, simply set enableWebSearch to true when calling chat()
  // The model will automatically perform web searches when needed.
  // The response will include reasoning and executed_tools with search_results
}

