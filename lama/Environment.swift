//
//  Environment.swift
//  lama
//
//  Created by Michal Jach on 01/11/2025.
//

import ComposableArchitecture

extension DependencyValues {
  var ollamaService: OllamaService {
    get { self[OllamaServiceKey.self] }
    set { self[OllamaServiceKey.self] = newValue }
  }
}

private struct OllamaServiceKey: DependencyKey {
  static let liveValue = OllamaService(userDefaultsService: .liveValue)
}
