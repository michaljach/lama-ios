//
//  GroqModels.swift
//  lama
//
//  Created by Michal Jach on 20/12/2025.
//

import Foundation

// MARK: - Request Models

// Default system prompt for all user messages
let groqDefaultSystemPrompt = "You are a helpful assistant. Always answer concisely and politely. Format responses for mobile in markdown. Do NOT return markdown tables unless the user explicitly requests a table. If information is best shown in a table, describe it in text instead, unless asked for a table."

// MARK: - Message Types

// Multimodal content support
enum MessageContent: Codable {
  case text(String)
  case array([ContentBlock])
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .text(let text):
      try container.encode(text)
    case .array(let blocks):
      try container.encode(blocks)
    }
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let text = try? container.decode(String.self) {
      self = .text(text)
    } else {
      let blocks = try container.decode([ContentBlock].self)
      self = .array(blocks)
    }
  }
}

struct ContentBlock: Codable {
  let type: String
  let text: String?
  let image_url: ImageUrl?
  
  enum CodingKeys: String, CodingKey {
    case type
    case text
    case image_url
  }
  
  // For text blocks
  init(type: String, text: String) {
    self.type = type
    self.text = text
    self.image_url = nil
  }
  
  // For image blocks with image_url object
  init(type: String, imageUrl: String) {
    self.type = type
    self.image_url = ImageUrl(url: imageUrl)
    self.text = nil
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)
    if let text = text {
      try container.encode(text, forKey: .text)
    }
    if let image_url = image_url {
      try container.encode(image_url, forKey: .image_url)
    }
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(String.self, forKey: .type)
    text = try container.decodeIfPresent(String.self, forKey: .text)
    image_url = try container.decodeIfPresent(ImageUrl.self, forKey: .image_url)
  }
}

struct ImageUrl: Codable {
  let url: String
  
  enum CodingKeys: String, CodingKey {
    case url
  }
  
  init(url: String) {
    self.url = url
  }
}

struct ChatMessage: Codable {
  let role: MessageRole
  let content: MessageContent
  let toolCalls: [GroqToolCall]?

  enum CodingKeys: String, CodingKey {
    case role
    case content
    case toolCalls = "tool_calls"
  }

  init(role: MessageRole, content: String, toolCalls: [GroqToolCall]? = nil) {
    self.role = role
    self.content = .text(content)
    self.toolCalls = toolCalls
  }
  
  init(role: MessageRole, content: MessageContent, toolCalls: [GroqToolCall]? = nil) {
    self.role = role
    self.content = content
    self.toolCalls = toolCalls
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(role, forKey: .role)
    try container.encode(content, forKey: .content)
    if let toolCalls = toolCalls {
      try container.encode(toolCalls, forKey: .toolCalls)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    role = try container.decode(MessageRole.self, forKey: .role)
    content = try container.decode(MessageContent.self, forKey: .content)
    toolCalls = try container.decodeIfPresent([GroqToolCall].self, forKey: .toolCalls)
  }
}

enum MessageRole: String, Codable {
  case system
  case user
  case assistant
}

extension Array where Element == ChatMessage {
  /// Prepends the default system prompt as a system message if not already present
  func withDefaultSystemPrompt() -> [ChatMessage] {
    if let first = self.first, first.role == .system { return self }
    return [ChatMessage(role: .system, content: groqDefaultSystemPrompt)] + self
  }
}

struct GroqChatRequest: Codable {
  let model: String
  let messages: [ChatMessage]
  let temperature: Double?
  let maxTokens: Int?
  let topP: Double?
  let stream: Bool
  let tools: [GroqTool]?
  let includeReasoning: Bool?
  
  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case temperature
    case maxTokens = "max_tokens"
    case topP = "top_p"
    case stream
    case tools
    case includeReasoning = "include_reasoning"
  }
  
  init(
    model: String,
    messages: [ChatMessage],
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    topP: Double? = nil,
    stream: Bool,
    tools: [GroqTool]? = nil,
    includeReasoning: Bool? = nil
  ) {
    self.model = model
    self.messages = messages
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.topP = topP
    self.stream = stream
    self.tools = tools
    self.includeReasoning = includeReasoning
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(model, forKey: .model)
    try container.encode(messages, forKey: .messages)
    try container.encode(stream, forKey: .stream)
    
    if let temperature = temperature {
      try container.encode(temperature, forKey: .temperature)
    }
    if let maxTokens = maxTokens {
      try container.encode(maxTokens, forKey: .maxTokens)
    }
    if let topP = topP {
      try container.encode(topP, forKey: .topP)
    }
    if let tools = tools {
      try container.encode(tools, forKey: .tools)
    }
    if let includeReasoning = includeReasoning {
      try container.encode(includeReasoning, forKey: .includeReasoning)
    }
  }
}

// MARK: - Tools

struct GroqTool: Codable {
  let type: String
  let function: GroqToolFunction
  
  init(type: String = "function", function: GroqToolFunction) {
    self.type = type
    self.function = function
  }
}

struct GroqToolFunction: Codable {
  let name: String
  let description: String
  let parameters: GroqToolParameters
}

struct GroqToolParameters: Codable {
  let type: String
  let properties: [String: GroqPropertyDefinition]
  let required: [String]
  
  init(type: String = "object", properties: [String: GroqPropertyDefinition], required: [String]) {
    self.type = type
    self.properties = properties
    self.required = required
  }
}

struct GroqPropertyDefinition: Codable {
  let type: String
  let description: String?
  
  init(type: String, description: String? = nil) {
    self.type = type
    self.description = description
  }
}

extension GroqTool {
  /// Creates the web_search tool definition
  static var webSearch: GroqTool {
    GroqTool(
      function: GroqToolFunction(
        name: "web_search",
        description: "Search the web for current information. Use this when you need up-to-date information or facts that you don't have in your knowledge base.",
        parameters: GroqToolParameters(
          properties: [
            "query": GroqPropertyDefinition(
              type: "string",
              description: "The search query to find information on the web"
            )
          ],
          required: ["query"]
        )
      )
    )
  }
}

// MARK: - Response Models

struct ChatResponse: Codable {
  let model: String?
  let createdAt: String?
  let message: ChatMessage?
  let done: Bool?
  let doneReason: String?
  let totalDuration: Int64?
  let loadDuration: Int64?
  let promptEvalCount: Int32?
  let promptEvalDuration: Int64?
  let evalCount: Int32?
  let evalDuration: Int64?
  let sources: [WebSearchSource]?
  let reasoning: String?

  enum CodingKeys: String, CodingKey {
    case model
    case createdAt = "created_at"
    case message
    case done
    case doneReason = "done_reason"
    case totalDuration = "total_duration"
    case loadDuration = "load_duration"
    case promptEvalCount = "prompt_eval_count"
    case promptEvalDuration = "prompt_eval_duration"
    case evalCount = "eval_count"
    case evalDuration = "eval_duration"
    case sources
    case reasoning
  }
}

struct GroqChatResponse: Codable {
  let id: String?
  let model: String?
  let choices: [GroqChoice]
  let usage: GroqUsage?
  let created: Int?
}

struct GroqChoice: Codable {
  let index: Int?
  let message: GroqMessage?
  let delta: GroqDelta?
  let finishReason: String?
  
  enum CodingKeys: String, CodingKey {
    case index
    case message
    case delta
    case finishReason = "finish_reason"
  }
}

struct GroqMessage: Codable {
  let role: String
  let content: String?
  let tool_calls: [GroqToolCall]?
  let executed_tools: [ExecutedTool]?
  let reasoning: String?
}

struct GroqDelta: Codable {
  let role: String?
  let content: String?
  let tool_calls: [GroqToolCall]?
  let executed_tools: [ExecutedTool]?
}

struct GroqToolCall: Codable {
  let id: String?
  let type: String?
  let function: GroqToolCallFunction
}

struct GroqToolCallFunction: Codable {
  let name: String
  let arguments: String
}

// MARK: - Executed Tools (for web search results)

struct ExecutedTool: Codable {
  let type: String?
  let search_results: SearchResultsContainer?
}

struct SearchResultsContainer: Codable {
  let results: [SearchResult]?
}

struct SearchResult: Codable {
  let title: String?
  let url: String?
  let content: String?
  let relevance_score: Double?
  
  enum CodingKeys: String, CodingKey {
    case title
    case url
    case content
    case relevance_score
  }
}

struct GroqUsage: Codable {
  let promptTokens: Int?
  let completionTokens: Int?
  let totalTokens: Int?
  
  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

// MARK: - Models List

struct GroqModelsResponse: Codable {
  let object: String
  let data: [GroqModel]
}

struct GroqModel: Codable {
  let id: String
  let object: String
  let owned_by: String
  let created: Int?
}

// MARK: - Web Search

struct WebSearchSource: Codable, Identifiable, Equatable {
  let id: String
  let title: String
  let url: String
  let content: String
  
  init(id: String = UUID().uuidString, title: String, url: String, content: String) {
    self.id = id
    self.title = title
    self.url = url
    self.content = content
  }
}

struct WebSearchResponse: Codable {
  let results: [WebSearchResult]
}

struct WebSearchResult: Codable {
  let title: String
  let url: String
  let content: String
}

// MARK: - Error Models

struct GroqErrorResponse: Codable {
  let error: GroqErrorDetail?
}

struct GroqErrorDetail: Codable {
  let message: String
  let type: String?
}

// MARK: - Errors

enum GroqError: LocalizedError {
  case invalidURL
  case encodingError(Error)
  case decodingError(Error)
  case networkError(Error)
  case invalidResponse
  case httpError(Int)
  case apiError(String)
  case missingAPIKey
  
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .encodingError(let error):
      return "Encoding error: \(error.localizedDescription)"
    case .decodingError(let error):
      return "Decoding error: \(error.localizedDescription)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid response"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .apiError(let message):
      return "API error: \(message)"
    case .missingAPIKey:
      return "Groq API key not configured"
    }
  }
}
