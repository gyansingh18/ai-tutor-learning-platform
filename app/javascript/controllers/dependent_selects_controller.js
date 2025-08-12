import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grade", "subject", "chapter"]
  static values = {
    subjects: Object,
    chapters: Object
  }

  connect() {
    this.clearSubjects()
    this.clearChapters()
  }

  gradeChanged() {
    const gradeId = this.gradeTarget.value

    this.clearSubjects()
    this.clearChapters()

    if (gradeId && this.subjectsValue[gradeId]) {
      this.loadSubjects(gradeId)
    }
  }

  subjectChanged() {
    const subjectId = this.subjectTarget.value

    this.clearChapters()

    if (subjectId && this.chaptersValue[subjectId]) {
      this.loadChapters(subjectId)
    }
  }

  loadSubjects(gradeId) {
    const subjects = this.subjectsValue[gradeId] || []
    this.populateSelect(this.subjectTarget, subjects, "Select a subject")
    this.subjectTarget.disabled = false
  }

  loadChapters(subjectId) {
    const chapters = this.chaptersValue[subjectId] || []
    this.populateSelect(this.chapterTarget, chapters, "Select a chapter")
    this.chapterTarget.disabled = false
  }

  populateSelect(selectElement, options, promptText) {
    selectElement.innerHTML = `<option value="">${promptText}</option>`

    options.forEach(option => {
      const optionElement = document.createElement("option")
      optionElement.value = option.id
      optionElement.textContent = option.name
      selectElement.appendChild(optionElement)
    })
  }

  clearSubjects() {
    this.subjectTarget.innerHTML = '<option value="">Select a subject</option>'
    this.subjectTarget.disabled = true
  }

  clearChapters() {
    this.chapterTarget.innerHTML = '<option value="">Select a chapter</option>'
    this.chapterTarget.disabled = true
  }
}
