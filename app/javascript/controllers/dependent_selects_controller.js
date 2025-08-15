import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grade", "subject", "chapter"]
  static values = {
    subjects: Object,
    chapters: Object
  }

  connect() {
    console.log("Dependent Selects Controller connected")
    this.clearSubjects()
    this.clearChapters()

    // Ensure proper initial state
    if (this.hasGradeTarget && this.hasSubjectTarget && this.hasChapterTarget) {
      this.gradeTarget.disabled = false
      this.subjectTarget.disabled = true
      this.chapterTarget.disabled = true
    }
  }

  gradeChanged() {
    const gradeId = this.gradeTarget.value
    console.log("Grade changed to:", gradeId)

    this.clearSubjects()
    this.clearChapters()

    if (gradeId && this.subjectsValue[gradeId]) {
      this.loadSubjects(gradeId)
    }
  }

  subjectChanged() {
    const subjectId = this.subjectTarget.value
    console.log("Subject changed to:", subjectId)

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
