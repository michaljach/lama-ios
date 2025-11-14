//
//  OllamaService.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import Foundation

/// Service for interacting with the Ollama API
actor OllamaService {
  private let urlSession: URLSession
  private let userDefaultsService: UserDefaultsService

  /// Initialize the Ollama service
  /// - Parameters:
  ///   - urlSession: Optional custom URLSession for testing
  ///   - userDefaultsService: Service for accessing user defaults
  init(urlSession: URLSession = .shared, userDefaultsService: UserDefaultsService = .liveValue) {
    self.urlSession = urlSession
    self.userDefaultsService = userDefaultsService
  }

  /// Get the base URL from settings or use default
  private var baseURL: String {
    userDefaultsService.getOllamaEndpoint()
  }
  
  /// Get the authorization token if set
  private var authToken: String? {
    userDefaultsService.getAuthToken()
  }
  
  /// Add authorization header to request if token is set
  private func addAuthorizationHeader(to request: inout URLRequest) {
    if let token = authToken, !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }
  
  // MARK: - Chat Completion
  
  /// Send a chat message and get a streaming response
  /// - Parameters:
  ///   - model: The model name to use (e.g., "llama2", "mistral")
  ///   - messages: Array of chat messages
  ///   - options: Optional generation options
  ///   - tools: Optional array of tools the model can use
  /// - Returns: AsyncThrowingStream of ChatResponse chunks
  func chat(
    model: String,
    messages: [ChatMessage],
    options: ChatOptions? = nil,
    tools: [Tool]? = nil
  ) async throws -> AsyncThrowingStream<ChatResponse, Error> {
    let request = ChatRequest(
      model: model,
      messages: messages,
      stream: true,
      options: options,
      tools: tools
    )

    return try await performStreamingRequest(
      endpoint: "/api/chat",
      request: request
    ) { data in
      try JSONDecoder().decode(ChatResponse.self, from: data)
    }
  }
  
  /// Send a chat message and get a complete response
  /// - Parameters:
  ///   - model: The model name to use
  ///   - messages: Array of chat messages
  ///   - options: Optional generation options
  ///   - tools: Optional array of tools the model can use
  /// - Returns: Complete ChatResponse
  func chatComplete(
    model: String,
    messages: [ChatMessage],
    options: ChatOptions? = nil,
    tools: [Tool]? = nil
  ) async throws -> ChatResponse {
    let request = ChatRequest(
      model: model,
      messages: messages,
      stream: false,
      options: options,
      tools: tools
    )

    return try await performRequest(
      endpoint: "/api/chat",
      request: request,
      responseType: ChatResponse.self
    )
  }
  
  // MARK: - Generate Text
  
  /// Generate text from a prompt with streaming
  /// - Parameters:
  ///   - model: The model name to use
  ///   - prompt: The text prompt
  ///   - options: Optional generation options
  ///   - context: Optional context from previous generation to preserve conversation history
  /// - Returns: AsyncThrowingStream of GenerateResponse chunks
  func generate(
    model: String,
    prompt: String,
    options: GenerateOptions? = nil,
    context: [Int]? = nil
  ) async throws -> AsyncThrowingStream<GenerateResponse, Error> {
    let request = GenerateRequest(
      model: model,
      prompt: prompt,
      stream: true,
      options: options,
      context: context
    )
    
    return try await performStreamingRequest(
      endpoint: "/api/generate",
      request: request
    ) { data in
      try JSONDecoder().decode(GenerateResponse.self, from: data)
    }
  }
  
  /// Generate text from a prompt and get complete response
  /// - Parameters:
  ///   - model: The model name to use
  ///   - prompt: The text prompt
  ///   - options: Optional generation options
  ///   - context: Optional context from previous generation to preserve conversation history
  /// - Returns: Complete GenerateResponse
  func generateComplete(
    model: String,
    prompt: String,
    options: GenerateOptions? = nil,
    context: [Int]? = nil
  ) async throws -> GenerateResponse {
    let request = GenerateRequest(
      model: model,
      prompt: prompt,
      stream: false,
      options: options,
      context: context
    )
    
    return try await performRequest(
      endpoint: "/api/generate",
      request: request,
      responseType: GenerateResponse.self
    )
  }
  
  // MARK: - Models
  
  /// List all available models
  /// - Returns: ListModelsResponse containing available models
  func listModels() async throws -> ListModelsResponse {
    guard let url = URL(string: "\(baseURL)/api/tags") else {
      throw OllamaError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"
    addAuthorizationHeader(to: &urlRequest)
    
    do {
      let (data, response) = try await urlSession.data(for: urlRequest)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw OllamaError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        if let errorResponse = try? JSONDecoder().decode(OllamaErrorResponse.self, from: data) {
          throw OllamaError.apiError(errorResponse.error)
        }
        throw OllamaError.httpError(httpResponse.statusCode)
      }
      
      return try JSONDecoder().decode(ListModelsResponse.self, from: data)
    } catch let error as OllamaError {
      throw error
    } catch {
      throw OllamaError.networkError(error)
    }
  }
  
  /// Show model information
  /// - Parameter name: The model name
  /// - Returns: ShowModelResponse with model details
  func showModel(name: String) async throws -> ShowModelResponse {
    let request = ShowModelRequest(name: name)
    return try await performRequest(
      endpoint: "/api/show",
      request: request,
      responseType: ShowModelResponse.self
    )
  }
  
  // MARK: - Web Search

  /// Perform a web search using Ollama's web search API
  /// - Parameters:
  ///   - query: The search query
  ///   - maxResults: Maximum number of results to return (default 5, max 10)
  /// - Returns: WebSearchResponse with search results
  func webSearch(query: String, maxResults: Int = 5) async throws -> WebSearchResponse {
    let request = WebSearchRequest(query: query, maxResults: maxResults)

    guard let url = URL(string: "https://ollama.com/api/web_search") else {
      throw OllamaError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthorizationHeader(to: &urlRequest)

    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw OllamaError.encodingError(error)
    }

    do {
      let (data, response) = try await urlSession.data(for: urlRequest)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw OllamaError.invalidResponse
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        if let errorResponse = try? JSONDecoder().decode(OllamaErrorResponse.self, from: data) {
          throw OllamaError.apiError(errorResponse.error)
        }
        throw OllamaError.httpError(httpResponse.statusCode)
      }

      return try JSONDecoder().decode(WebSearchResponse.self, from: data)
    } catch let error as OllamaError {
      throw error
    } catch {
      throw OllamaError.networkError(error)
    }
  }

  // MARK: - Private Helpers
  
  private func performRequest<T: Codable, U: Codable>(
    endpoint: String,
    request: T,
    responseType: U.Type
  ) async throws -> U {
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
      throw OllamaError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthorizationHeader(to: &urlRequest)
    
    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw OllamaError.encodingError(error)
    }
    
    do {
      let (data, response) = try await urlSession.data(for: urlRequest)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        throw OllamaError.invalidResponse
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        if let errorResponse = try? JSONDecoder().decode(OllamaErrorResponse.self, from: data) {
          throw OllamaError.apiError(errorResponse.error)
        }
        throw OllamaError.httpError(httpResponse.statusCode)
      }
      
      return try JSONDecoder().decode(U.self, from: data)
    } catch let error as OllamaError {
      throw error
    } catch {
      throw OllamaError.networkError(error)
    }
  }
  
  private func performStreamingRequest<T: Codable, U: Codable>(
    endpoint: String,
    request: T,
    decoder: @escaping (Data) throws -> U
  ) async throws -> AsyncThrowingStream<U, Error> {
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
      throw OllamaError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Add authorization header if token is set
    if let token = authToken, !token.isEmpty {
      urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    do {
      urlRequest.httpBody = try JSONEncoder().encode(request)
    } catch {
      throw OllamaError.encodingError(error)
    }
    
    return AsyncThrowingStream { continuation in
      Task {
        do {
          let (bytes, response) = try await urlSession.bytes(for: urlRequest)
          
          guard let httpResponse = response as? HTTPURLResponse else {
            continuation.finish(throwing: OllamaError.invalidResponse)
            return
          }
          
          guard (200...299).contains(httpResponse.statusCode) else {
            var errorData = Data()
            for try await byte in bytes {
              errorData.append(byte)
            }
            if let errorResponse = try? JSONDecoder().decode(OllamaErrorResponse.self, from: errorData) {
              continuation.finish(throwing: OllamaError.apiError(errorResponse.error))
            } else {
              continuation.finish(throwing: OllamaError.httpError(httpResponse.statusCode))
            }
            return
          }
          
          var lineBuffer = [UInt8]()
          
          for try await byte in bytes {
            lineBuffer.append(byte)
            
            // Check for complete JSON objects (newline-delimited)
            if byte == 0x0A { // newline character
              if !lineBuffer.isEmpty {
                let line = Data(lineBuffer.dropLast()) // Remove newline
                if !line.isEmpty {
                  do {
                    let decoded = try decoder(line)
                    continuation.yield(decoded)
                  } catch {
                    continuation.finish(throwing: OllamaError.decodingError(error))
                    return
                  }
                }
                lineBuffer.removeAll()
              }
            }
          }
          
          // Process remaining buffer (last line without newline)
          if !lineBuffer.isEmpty {
            let line = Data(lineBuffer)
            do {
              let decoded = try decoder(line)
              continuation.yield(decoded)
            } catch {
              continuation.finish(throwing: OllamaError.decodingError(error))
              return
            }
          }
          
          continuation.finish()
        } catch {
          continuation.finish(throwing: OllamaError.networkError(error))
        }
      }
    }
  }
}

