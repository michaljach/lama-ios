//
//  Environment.swift
//  lama
//
//  Created by Michal Jach on 01/11/2025.
//

import ComposableArchitecture

extension DependencyValues {
  var groqService: GroqService {
    get { self[GroqServiceKey.self] }
    set { self[GroqServiceKey.self] = newValue }
  }
}

private struct GroqServiceKey: DependencyKey {
  static let liveValue = GroqService(userDefaultsService: .liveValue)
}
