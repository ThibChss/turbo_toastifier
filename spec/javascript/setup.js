// Jest setup file for JavaScript tests
import { jest, beforeEach, afterEach } from '@jest/globals'

// Mock window.requestAnimationFrame
global.requestAnimationFrame = (callback) => {
  return setTimeout(callback, 0)
}

// Mock window.cancelAnimationFrame
global.cancelAnimationFrame = (id) => {
  clearTimeout(id)
}

// Mock Date.now for consistent timing in tests
let mockTime = 0
global.Date.now = jest.fn(() => mockTime)

// Helper to advance time in tests
global.advanceTime = (ms) => {
  mockTime += ms
  jest.advanceTimersByTime(ms)
}

// Reset time before each test
beforeEach(() => {
  mockTime = 0
  jest.useFakeTimers()
})

afterEach(() => {
  jest.useRealTimers()
})
