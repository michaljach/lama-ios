//
//  OllamaModels.swift
//  lama
//
//  Created by Michal Jach on 31/10/2025.
//

import Foundation

// MARK: - Request Models

struct ChatRequest {
  let model: String
  let messages: [ChatMessage]
  let stream: Bool
  let options: ChatOptions?
  
  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case stream
    case options
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

struct ChatMessage {
  let role: MessageRole
  let content: String
}

nonisolated extension ChatMessage: Codable {}

enum MessageRole: String {
  case system
  case user
  case assistant
}

nonisolated extension MessageRole: Codable {}

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

