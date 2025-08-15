import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    // Listen for Turbo events to detect sign out
    document.addEventListener('turbo:before-render', this.handleBeforeRender.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:before-render', this.handleBeforeRender.bind(this))
  }

  handleBeforeRender(event) {
    // If we're being redirected to root after sign out, force a full page reload
    if (event.detail.url === '/' || event.detail.url.endsWith('/')) {
      // Check if user is signed out
      if (!document.body.dataset.userSignedIn) {
        event.preventDefault()
        window.location.href = '/'
      }
    }
  }

  // Handle sign out form submission
  signOut(event) {
    event.preventDefault()
    
    // Submit the form normally (without Turbo)
    const form = event.target.closest('form')
    if (form) {
      form.submit()
    } else {
      // If no form, redirect to sign out path
      window.location.href = '/users/sign_out'
    }
  }
}
