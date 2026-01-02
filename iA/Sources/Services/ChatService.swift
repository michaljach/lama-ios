//
//  ChatService.swift
//  iA
//
//  Created by Michal Jach on 02/01/2026.
//

import ComposableArchitecture
import Foundation
import UIKit

enum ChatError: LocalizedError {
  case noAPIKey
  case networkError(String)
  case invalidResponse
  case apiError(String)
  
  var errorDescription: String? {
    switch self {
    case .noAPIKey:
      return "API key not configured. Please add your Google AI API key in Settings."
    case .networkError(let message):
      return "Network error: \(message)"
    case .invalidResponse:
      return "Invalid response from API. Please try again."
    case .apiError(let message):
      return message
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .noAPIKey:
      return "Go to Settings and enter your Google AI API key. Get one at https://aistudio.google.com/apikey"
    case .networkError:
      return "Check your internet connection and try again."
    case .invalidResponse:
      return "The API returned an unexpected response. Please try again or check your model selection."
    case .apiError(let message):
      if message.contains("API_KEY_INVALID") || message.contains("invalid") {
        return "Your API key appears to be invalid. Please check it in Settings."
      } else if message.contains("quota") || message.contains("limit") {
        return "You've reached your API quota limit. Check your Google AI Console."
      } else if message.contains("404") || message.contains("not found") {
        return "The model '\(message)' may not be available. Try selecting a different model."
      }
      return "Please try again or contact support if the problem persists."
    }
  }
}

struct WebSource: Equatable, Codable, Identifiable {
  let id: UUID
  let title: String
  let url: String
  
  init(id: UUID = UUID(), title: String, url: String) {
    self.id = id
    self.title = title
    self.url = url
  }
}

struct ChatResponse: Equatable {
  let text: String
  let sources: [WebSource]
}

enum ChatStreamEvent: Equatable {
  case token(String)
  case complete(sources: [WebSource])
  case error(String)
}

struct ChatService {
  var streamMessage: @Sendable (
    _ messages: [ChatMessage],
    _ model: String,
    _ temperature: Double,
    _ maxTokens: Int,
    _ webSearchEnabled: Bool
  ) -> AsyncThrowingStream<ChatStreamEvent, Error>
}

extension ChatService: DependencyKey {
  static let liveValue = Self(
    streamMessage: { messages, model, temperature, maxTokens, webSearchEnabled in
      return streamGoogleAIMessage(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        webSearchEnabled: webSearchEnabled
      )
    }
  )
  
  static let testValue = Self(
    streamMessage: { _, _, _, _, _ in
      AsyncThrowingStream { continuation in
        continuation.yield(.token("Test "))
        continuation.yield(.token("response"))
        continuation.yield(.complete(sources: []))
        continuation.finish()
      }
    }
  )
}

extension DependencyValues {
  var chatService: ChatService {
    get { self[ChatService.self] }
    set { self[ChatService.self] = newValue }
  }
}

// MARK: - Google AI Streaming Implementation
private func streamGoogleAIMessage(
  messages: [ChatMessage],
  model: String,
  temperature: Double,
  maxTokens: Int,
  webSearchEnabled: Bool
) -> AsyncThrowingStream<ChatStreamEvent, Error> {
  return AsyncThrowingStream { continuation in
    Task {
      do {
        let apiKey = UserDefaults.standard.string(forKey: "googleAIAPIKey") ?? ""
        guard !apiKey.isEmpty else {
          throw ChatError.noAPIKey
        }
        
        // Model name should NOT have "models/" prefix for the URL
        let apiModel = model.replacingOccurrences(of: "models/", with: "")
        
        // Use streamGenerateContent endpoint for streaming
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(apiModel):streamGenerateContent?key=\(apiKey)&alt=sse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct GoogleAIMessage: Codable {
          let role: String
          let parts: [Part]
          
          struct Part: Codable {
            let text: String?
            let inlineData: InlineData?
            
            enum CodingKeys: String, CodingKey {
              case text
              case inlineData = "inline_data"
            }
            
            struct InlineData: Codable {
              let mimeType: String
              let data: String
              
              enum CodingKeys: String, CodingKey {
                case mimeType = "mime_type"
                case data
              }
            }
            
            init(text: String) {
              self.text = text
              self.inlineData = nil
            }
            
            init(image: UIImage) {
              self.text = nil
              // Convert UIImage to JPEG data and base64 encode
              if let imageData = image.jpegData(compressionQuality: 0.8) {
                self.inlineData = InlineData(
                  mimeType: "image/jpeg",
                  data: imageData.base64EncodedString()
                )
              } else {
                self.inlineData = nil
              }
            }
          }
        }
        
        struct GoogleAIRequest: Codable {
          let contents: [GoogleAIMessage]
          let generationConfig: GenerationConfig
          let tools: [Tool]?
          
          struct GenerationConfig: Codable {
            let temperature: Double
            let maxOutputTokens: Int
            
            enum CodingKeys: String, CodingKey {
              case temperature
              case maxOutputTokens = "max_output_tokens"
            }
          }
          
          struct Tool: Codable {
            let googleSearch: GoogleSearch
            
            struct GoogleSearch: Codable {
              // Empty object to enable Google Search
            }
            
            enum CodingKeys: String, CodingKey {
              case googleSearch = "google_search"
            }
          }
        }
        
        // Convert chat messages to Google AI format with system prompt
        var googleMessages: [GoogleAIMessage] = []
        
        // Add system prompt as first user message if this is the first message
        if messages.count == 1 && messages.first?.role == "user" {
          let systemPrompt = """
          You are a helpful AI assistant. When responding:
          
          • Use bullet points to organize information clearly
          • Format lists with proper markdown bullets (•, -, or *)
          • Use tables when comparing multiple items or showing structured data
          • Use **bold** for emphasis on key terms
          • Use `code blocks` for technical terms, commands, or code
          • Break down complex explanations into digestible sections
          • Use numbered lists (1., 2., 3.) for sequential steps
          
          Keep your responses well-structured, scannable, and visually appealing using markdown formatting.
          """
          
          googleMessages.append(
            GoogleAIMessage(
              role: "user",
              parts: [GoogleAIMessage.Part(text: systemPrompt)]
            )
          )
          
          googleMessages.append(
            GoogleAIMessage(
              role: "model",
              parts: [GoogleAIMessage.Part(text: "Understood. I'll format my responses with clear structure using bullet points, tables, bold text, and code blocks to make information easy to scan and understand.")]
            )
          )
        }
        
        for message in messages {
          let googleRole = message.role == "user" ? "user" : "model"
          var parts: [GoogleAIMessage.Part] = []
          
          // Add images first if present
          for image in message.images {
            parts.append(GoogleAIMessage.Part(image: image))
          }
          
          // Add text content if not empty
          if !message.content.isEmpty {
            parts.append(GoogleAIMessage.Part(text: message.content))
          }
          
          // Skip empty messages
          guard !parts.isEmpty else { continue }
          
          googleMessages.append(
            GoogleAIMessage(
              role: googleRole,
              parts: parts
            )
          )
        }
        
        let googleRequest = GoogleAIRequest(
          contents: googleMessages,
          generationConfig: GoogleAIRequest.GenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
          ),
          tools: webSearchEnabled ? [
            GoogleAIRequest.Tool(
              googleSearch: GoogleAIRequest.Tool.GoogleSearch()
            )
          ] : nil
        )
        
        request.httpBody = try JSONEncoder().encode(googleRequest)
        
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          throw ChatError.invalidResponse
        }
        
        
        if httpResponse.statusCode != 200 {
          throw ChatError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        struct StreamResponse: Codable {
          let candidates: [Candidate]?
          let error: ErrorInfo?
          
          struct ErrorInfo: Codable {
            let code: Int?
            let message: String?
            let status: String?
          }
          
          struct Candidate: Codable {
            let content: Content
            let finishReason: String?
            let groundingMetadata: GroundingMetadata?
            
            struct Content: Codable {
              let parts: [Part]
              
              struct Part: Codable {
                let text: String?
              }
            }
            
            struct GroundingMetadata: Codable {
              let groundingChunks: [GroundingChunk]?
              let webSearchQueries: [String]?
              
              enum CodingKeys: String, CodingKey {
                case groundingChunks = "groundingChunks"
                case webSearchQueries = "webSearchQueries"
              }
              
              struct GroundingChunk: Codable {
                let web: WebChunk?
                
                struct WebChunk: Codable {
                  let uri: String?
                  let title: String?
                }
              }
            }
          }
        }
        
        var allSources: [WebSource] = []
        
        // Parse SSE stream
        for try await line in bytes.lines {
          // SSE format: "data: {json}"
          if line.hasPrefix("data: ") {
            let jsonString = String(line.dropFirst(6)) // Remove "data: "
            
            guard let jsonData = jsonString.data(using: .utf8) else { continue }
            
            do {
              let streamResponse = try JSONDecoder().decode(StreamResponse.self, from: jsonData)
              
              // Check for error
              if let error = streamResponse.error {
                let errorMsg = error.message ?? "Unknown error"
                continuation.yield(.error(errorMsg))
                throw ChatError.apiError(errorMsg)
              }
              
              // Extract text chunk
              if let candidates = streamResponse.candidates,
                 let candidate = candidates.first,
                 let text = candidate.content.parts.first?.text {
                continuation.yield(.token(text))
              }
              
              // Extract sources from grounding metadata
              if let candidates = streamResponse.candidates,
                 let candidate = candidates.first,
                 let groundingMetadata = candidate.groundingMetadata,
                 let chunks = groundingMetadata.groundingChunks {
                for chunk in chunks {
                  if let web = chunk.web,
                     let uri = web.uri,
                     let title = web.title {
                    let source = WebSource(title: title, url: uri)
                    if !allSources.contains(where: { $0.url == uri }) {
                      allSources.append(source)
                    }
                  }
                }
              }
            } catch {
            }
          }
        }
        
        // Send completion with sources
        continuation.yield(.complete(sources: allSources))
        continuation.finish()
        
        
      } catch {
        continuation.finish(throwing: error)
      }
    }
  }
}
