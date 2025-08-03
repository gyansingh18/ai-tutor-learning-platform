import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "form", "textarea", "submitButton", "loadingIndicator"]

  connect() {
    console.log("Chat controller connected")
    this.setupEventListeners()
  }

  disconnect() {
    console.log("Chat controller disconnected")
  }

  setupEventListeners() {
    // Auto-resize textarea
    if (this.hasTextareaTarget) {
      this.textareaTarget.addEventListener('input', this.resizeTextarea.bind(this))
      this.textareaTarget.addEventListener('keydown', this.handleKeydown.bind(this))
    }

    // Turbo events for scrolling
    document.addEventListener('turbo:render', this.handleRender.bind(this))
    document.addEventListener('turbo:stream-render', this.handleStreamRender.bind(this))
  }

  resizeTextarea() {
    const textarea = this.textareaTarget
    textarea.style.height = 'auto'
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px'
  }

  handleKeydown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      // Let the form handle submission naturally
      return
    }
  }

  handleRender() {
    // Scroll to bottom after new content is rendered
    setTimeout(() => {
      this.scrollToBottom()
    }, 100)
  }

  handleStreamRender() {
    // Scroll to bottom after Turbo Stream renders new content
    setTimeout(() => {
      this.scrollToBottom()
    }, 50)
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      const messages = this.messagesTarget
      messages.scrollTop = messages.scrollHeight
    }
  }
}
