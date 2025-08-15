import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen for page load to check if we need to refresh after sign out
    this.checkSignOutState()
  }

  checkSignOutState() {
    // If we're on the homepage and user is signed out, ensure proper rendering
    if (window.location.pathname === '/' && !document.body.dataset.userSignedIn) {
      // Check if this is a fresh page load or navigation
      if (performance.navigation.type !== 1) {
        // This is a navigation, force reload to ensure proper rendering
        window.location.reload()
      }
    }
  }
}
