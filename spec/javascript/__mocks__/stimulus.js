// Mock Stimulus Controller for testing
// This matches: import { Controller as BaseController } from '@hotwired/stimulus'
export class Controller {
  static values = {}

  constructor(element, identifier) {
    this.element = element
    this.identifier = identifier
    this.application = null
  }

  connect() {}
  disconnect() {}
}
