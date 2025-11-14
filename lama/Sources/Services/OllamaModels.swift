//
//  OllamaModels.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import Foundation

// MARK: - Request Models

// Default system prompt for all user messages
let defaultSystemPrompt = "You are a helpful assistant. Always answer concisely and politely. Format responses for mobile in markdown. Do NOT render tables unless the user explicitly requests a table. If information is best shown in a table, describe it in text instead, unless asked for a table."

extension Array where Element == ChatMessage {
  /// Prepends the default system prompt as a system message if not already present
  func withDefaultSystemPrompt() -> [ChatMessage] {
    if let first = self.first, first.role == .system { return self }
    return [ChatMessage(role: .system, content: defaultSystemPrompt)] + self
  }
}

struct ChatRequest {
  let model: String
  let messages: [ChatMessage]
  let stream: Bool
  let options: ChatOptions?
  let tools: [Tool]?

  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case stream
    case options
    case tools
  }
}

nonisolated extension ChatRequest: Codable {}

struct GenerateRequest {
  let model: String
  let prompt: String
  let stream: Bool
  let options: GenerateOptions?
  let context: [Int]?
  
  enum CodingKeys: String, CodingKey {
    case model
    case prompt
    case stream
    case options
    case context
  }
}

nonisolated extension GenerateRequest: Codable {}

struct ShowModelRequest {
  let name: String
}

nonisolated extension ShowModelRequest: Codable {}

struct EmptyRequest {}

nonisolated extension EmptyRequest: Codable {}

// MARK: - Response Models

struct ChatResponse {
  let model: String?
  let createdAt: String?
  let message: ChatMessage?
  let done: Bool?
  let doneReason: String?
  let totalDuration: Int64?
  let loadDuration: Int64?
  let promptEvalCount: Int?
  let promptEvalDuration: Int64?
  let evalCount: Int?
  let evalDuration: Int64?

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
  }
}

nonisolated extension ChatResponse: Codable {}

struct GenerateResponse {
  let model: String?
  let createdAt: String?
  let response: String?
  let done: Bool?
  let doneReason: String?
  let context: [Int]?
  let totalDuration: Int64?
  let loadDuration: Int64?
  let promptEvalCount: Int?
  let promptEvalDuration: Int64?
  let evalCount: Int?
  let evalDuration: Int64?
  
  enum CodingKeys: String, CodingKey {
    case model
    case createdAt = "created_at"
    case response
    case done
    case doneReason = "done_reason"
    case context
    case totalDuration = "total_duration"
    case loadDuration = "load_duration"
    case promptEvalCount = "prompt_eval_count"
    case promptEvalDuration = "prompt_eval_duration"
    case evalCount = "eval_count"
    case evalDuration = "eval_duration"
  }
}

nonisolated extension GenerateResponse: Codable {}

struct ListModelsResponse {
  let models: [ModelInfo]
}

nonisolated extension ListModelsResponse: Codable {}

struct ShowModelResponse {
  let modelfile: String
  let parameters: String
  let template: String
  let details: ModelDetails
  let system: String?
  let license: String?
}

nonisolated extension ShowModelResponse: Codable {}

struct ModelInfo {
  let name: String
  let modifiedAt: String
  let size: Int64
  let digest: String
  let details: ModelDetails?
  
  enum CodingKeys: String, CodingKey {
    case name
    case modifiedAt = "modified_at"
    case size
    case digest
    case details
  }
}

nonisolated extension ModelInfo: Codable {}

struct ModelDetails {
  let parentModel: String?
  let format: String?
  let family: String?
  let parameterSize: String?
  let quantizationLevel: String?
  
  enum CodingKeys: String, CodingKey {
    case parentModel = "parent_model"
    case format
    case family
    case parameterSize = "parameter_size"
    case quantizationLevel = "quantization_level"
  }
}

nonisolated extension ModelDetails: Codable {}

struct ChatMessage: Codable {
  let role: MessageRole
  let content: String
  let toolCalls: [ToolCall]?

  enum CodingKeys: String, CodingKey {
    case role
    case content
    case toolCalls = "tool_calls"
  }

  init(role: MessageRole, content: String, toolCalls: [ToolCall]? = nil) {
    self.role = role
    self.content = content
    self.toolCalls = toolCalls
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    role = try container.decode(MessageRole.self, forKey: .role)
    content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
    toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(role, forKey: .role)
    try container.encode(content, forKey: .content)
    if let toolCalls = toolCalls {
      try container.encode(toolCalls, forKey: .toolCalls)
    }
  }
}

enum MessageRole: String {
  case system
  case user
  case assistant
  case tool
}

nonisolated extension MessageRole: Codable {}

// MARK: - Tools

struct Tool {
  let type: String
  let function: ToolFunction

  init(type: String = "function", function: ToolFunction) {
    self.type = type
    self.function = function
  }

  /// Creates the web_search tool definition
  static var webSearch: Tool {
    Tool(
      function: ToolFunction(
        name: "web_search",
        description: "Search the web for current information. Use this when you need up-to-date information or facts that you don't have in your knowledge base.",
        parameters: ToolFunctionParameters(
          properties: [
            "query": ToolPropertyDefinition(
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

nonisolated extension Tool: Codable {}

struct ToolFunction {
  let name: String
  let description: String
  let parameters: ToolFunctionParameters
}

nonisolated extension ToolFunction: Codable {}

struct ToolFunctionParameters {
  let type: String
  let properties: [String: ToolPropertyDefinition]
  let required: [String]

  init(type: String = "object", properties: [String: ToolPropertyDefinition], required: [String]) {
    self.type = type
    self.properties = properties
    self.required = required
  }
}

nonisolated extension ToolFunctionParameters: Codable {}

struct ToolPropertyDefinition {
  let type: String
  let description: String?

  init(type: String, description: String? = nil) {
    self.type = type
    self.description = description
  }
}

nonisolated extension ToolPropertyDefinition: Codable {}

struct ToolCall: Codable {
  let id: String?
  let type: String?
  let function: ToolCallFunction

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case function
  }

  init(id: String? = nil, type: String? = nil, function: ToolCallFunction) {
    self.id = id
    self.type = type
    self.function = function
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    function = try container.decode(ToolCallFunction.self, forKey: .function)
  }
}

struct ToolCallFunction: Codable {
  let name: String
  let arguments: String

  enum CodingKeys: String, CodingKey {
    case name
    case arguments
  }

  init(name: String, arguments: String) {
    self.name = name
    self.arguments = arguments
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)

    // Arguments can be either a string or a JSON object, so we need to handle both
    if let argumentsString = try? container.decode(String.self, forKey: .arguments) {
      arguments = argumentsString
    } else if let argumentsDict = try? container.decode([String: AnyCodable].self, forKey: .arguments) {
      // Convert dictionary to JSON string
      if let jsonData = try? JSONEncoder().encode(argumentsDict),
         let jsonString = String(data: jsonData, encoding: .utf8) {
        arguments = jsonString
      } else {
        arguments = "{}"
      }
    } else {
      arguments = "{}"
    }
  }
}

// Helper to decode any JSON value
struct AnyCodable: Codable {
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let bool = try? container.decode(Bool.self) {
      value = bool
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let double = try? container.decode(Double.self) {
      value = double
    } else if let string = try? container.decode(String.self) {
      value = string
    } else if let array = try? container.decode([AnyCodable].self) {
      value = array.map { $0.value }
    } else if let dictionary = try? container.decode([String: AnyCodable].self) {
      value = dictionary.mapValues { $0.value }
    } else {
      value = NSNull()
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    case let array as [Any]:
      try container.encode(array.map { AnyCodable($0) })
    case let dictionary as [String: Any]:
      try container.encode(dictionary.mapValues { AnyCodable($0) })
    default:
      try container.encodeNil()
    }
  }
}

// MARK: - Web Search

struct WebSearchRequest {
  let query: String
  let maxResults: Int?

  enum CodingKeys: String, CodingKey {
    case query
    case maxResults = "max_results"
  }

  init(query: String, maxResults: Int? = 5) {
    self.query = query
    self.maxResults = maxResults
  }
}

nonisolated extension WebSearchRequest: Codable {}

struct WebSearchResponse {
  let results: [WebSearchResult]
}

nonisolated extension WebSearchResponse: Codable {}

struct WebSearchResult {
  let title: String
  let url: String
  let content: String
}

nonisolated extension WebSearchResult: Codable {}

// MARK: - Options

struct ChatOptions {
  let temperature: Double?
  let topP: Double?
  let topK: Int?
  let repeatPenalty: Double?
  let seed: Int?
  // The maximum number of tokens to predict (Ollama option: num_predict)
  let numPredict: Int?
  
  enum CodingKeys: String, CodingKey {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case repeatPenalty = "repeat_penalty"
    case seed
    case numPredict = "num_predict"
  }
  
  init(
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    repeatPenalty: Double? = nil,
    seed: Int? = nil,
    numPredict: Int? = nil
  ) {
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.repeatPenalty = repeatPenalty
    self.seed = seed
    self.numPredict = numPredict
  }
}

nonisolated extension ChatOptions: Codable {}

struct GenerateOptions {
  let temperature: Double?
  let topP: Double?
  let topK: Int?
  let repeatPenalty: Double?
  let seed: Int?
  // The maximum number of tokens to predict (Ollama option: num_predict)
  let numPredict: Int?
  
  enum CodingKeys: String, CodingKey {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case repeatPenalty = "repeat_penalty"
    case seed
    case numPredict = "num_predict"
  }
  
  init(
    temperature: Double? = nil,
    topP: Double? = nil,
    topK: Int? = nil,
    repeatPenalty: Double? = nil,
    seed: Int? = nil,
    numPredict: Int? = nil
  ) {
    self.temperature = temperature
    self.topP = topP
    self.topK = topK
    self.repeatPenalty = repeatPenalty
    self.seed = seed
    self.numPredict = numPredict
  }
}

nonisolated extension GenerateOptions: Codable {}

// MARK: - Error Models

struct OllamaErrorResponse {
  let error: String
}

nonisolated extension OllamaErrorResponse: Codable {}

// MARK: - Errors

enum OllamaError: LocalizedError {
  case invalidURL
  case encodingError(Error)
  case decodingError(Error)
  case networkError(Error)
  case invalidResponse
  case httpError(Int)
  case apiError(String)
  
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
    }
  }
}

