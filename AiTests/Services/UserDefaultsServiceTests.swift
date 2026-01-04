//
//  UserDefaultsServiceTests.swift
//  iATests
//
//  Created by Test Suite on 31/12/2025.
//

import XCTest
import ComposableArchitecture

final class UserDefaultsServiceTests: XCTestCase {
  
  func test_getDefaultModel_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let model = service.getDefaultModel()
    XCTAssertEqual(model, "openai/gpt-oss:120b")
  }
  
  func test_getTemperature_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let temperature = service.getTemperature()
    XCTAssertEqual(temperature, 0.7)
  }
  
  func test_getMaxTokens_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let maxTokens = service.getMaxTokens()
    XCTAssertEqual(maxTokens, 640)
  }
  
  func test_isWebSearchEnabled_returnsDefaultValue() {
    let service = UserDefaultsService.testValue
    let enabled = service.isWebSearchEnabled()
    XCTAssertTrue(enabled)
  }
  
  func test_setAndGetDefaultModel() {
    var userDefaults: [String: Any] = [:]
    
    let service = UserDefaultsService(
      getDefaultModel: {
        userDefaults["defaultModel"] as? String ?? "openai/gpt-oss:120b"
      },
      setDefaultModel: { value in
        userDefaults["defaultModel"] = value
      },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: { 640 },
      setMaxTokens: { _ in },
      isWebSearchEnabled: { true },
      setWebSearchEnabled: { _ in },
      resetToDefaults: { }
    )
    
    let newModel = "mixtral-8x7b-32768"
    service.setDefaultModel(newModel)
    XCTAssertEqual(service.getDefaultModel(), newModel)
  }
  
  func test_setAndGetTemperature() {
    var userDefaults: [String: Any] = [:]
    
    let service = UserDefaultsService(
      getDefaultModel: { "openai/gpt-oss:120b" },
      setDefaultModel: { _ in },
      getTemperature: {
        userDefaults["temperature"] as? Double ?? 0.7
      },
      setTemperature: { value in
        userDefaults["temperature"] = value
      },
      getMaxTokens: { 640 },
      setMaxTokens: { _ in },
      isWebSearchEnabled: { true },
      setWebSearchEnabled: { _ in },
      resetToDefaults: { }
    )
    
    let newTemperature = 0.5
    service.setTemperature(newTemperature)
    XCTAssertEqual(service.getTemperature(), newTemperature)
  }
  
  func test_setAndGetMaxTokens() {
    var userDefaults: [String: Any] = [:]
    
    let service = UserDefaultsService(
      getDefaultModel: { "openai/gpt-oss:120b" },
      setDefaultModel: { _ in },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: {
        userDefaults["maxTokens"] as? Int ?? 640
      },
      setMaxTokens: { value in
        userDefaults["maxTokens"] = value
      },
      isWebSearchEnabled: { true },
      setWebSearchEnabled: { _ in },
      resetToDefaults: { }
    )
    
    let newMaxTokens = 2000
    service.setMaxTokens(newMaxTokens)
    XCTAssertEqual(service.getMaxTokens(), newMaxTokens)
  }
  
  func test_setAndGetWebSearchEnabled() {
    var userDefaults: [String: Any] = [:]
    
    let service = UserDefaultsService(
      getDefaultModel: { "openai/gpt-oss:120b" },
      setDefaultModel: { _ in },
      getTemperature: { 0.7 },
      setTemperature: { _ in },
      getMaxTokens: { 640 },
      setMaxTokens: { _ in },
      isWebSearchEnabled: {
        userDefaults["webSearchEnabled"] as? Bool ?? true
      },
      setWebSearchEnabled: { value in
        userDefaults["webSearchEnabled"] = value
      },
      resetToDefaults: { }
    )
    
    service.setWebSearchEnabled(false)
    XCTAssertFalse(service.isWebSearchEnabled())
    
    service.setWebSearchEnabled(true)
    XCTAssertTrue(service.isWebSearchEnabled())
  }
}
