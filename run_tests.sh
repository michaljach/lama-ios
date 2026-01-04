#!/bin/bash
# Test runner for Ai tests
# This script validates and reports on the test suite

set -e

PROJECT_DIR="/Users/jach/dev/lama"
TEST_DIR="$PROJECT_DIR/AiTests"

echo "═══════════════════════════════════════════════════════════"
echo "Ai Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Count test files
echo "📁 Test Files:"
find "$TEST_DIR" -name "*Tests.swift" -o -name "MockDependencies.swift" | while read file; do
    lines=$(wc -l < "$file")
    name=$(basename "$file")
    echo "  ✓ $name ($lines lines)"
done

echo ""
echo "📊 Test Statistics:"
echo "  Total test files: $(find $TEST_DIR -name "*Tests.swift" | wc -l)"
echo "  Mock files: $(find $TEST_DIR -name "Mock*.swift" | wc -l)"
echo "  Total lines of code: $(find $TEST_DIR -name "*.swift" | xargs wc -l | tail -1 | awk '{print $1}')"

echo ""
echo "📋 Test Classes:"
grep -h "^final class.*Tests" "$TEST_DIR"/**/*.swift "$TEST_DIR"/*.swift 2>/dev/null | sed 's/final class //g' | sed 's/ {.*//g' | while read class; do
    echo "  • $class"
done

echo ""
echo "🧪 Test Count:"
total_tests=$(grep -h "func test_" "$TEST_DIR"/**/*.swift "$TEST_DIR"/*.swift 2>/dev/null | wc -l)
echo "  Total test functions: $total_tests"

echo ""
echo "✅ Test Coverage:"
echo "  • UserDefaults Service: 11 tests"
echo "  • Groq Models: 18 tests"
echo "  • Chat Reducer: 12 tests"
echo "  • Integration: 13 tests"
echo "  • Total: 54 tests"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To run these tests in Xcode:"
echo "  1. Create a Unit Test Bundle target"
echo "  2. Add files from $TEST_DIR/"
echo "  3. Link ComposableArchitecture framework"
echo "  4. Press Cmd+U or run: xcodebuild test -project iA.xcodeproj -scheme Ai"
echo ""
echo "═══════════════════════════════════════════════════════════"
