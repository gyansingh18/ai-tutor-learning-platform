import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]

  connect() {
    // Add keyboard shortcut (Ctrl/Cmd + K)
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    // Check for Ctrl+K (Windows/Linux) or Cmd+K (Mac)
    if ((event.ctrlKey || event.metaKey) && event.key === "k") {
      event.preventDefault()
      this.focusInput()
    }
  }

  focusInput() {
    if (this.hasInputTarget) {
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  submitForm() {
    if (this.hasFormTarget && this.inputTarget.value.trim().length >= 2) {
      this.formTarget.submit()
    }
  }
}
