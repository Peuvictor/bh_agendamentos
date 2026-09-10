import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "links"]

  connect() {
    this.desktop = window.matchMedia("(min-width: 1280px)")
    this.resize = () => this.reset()
    this.desktop.addEventListener("change", this.resize)
    this.reset()
  }

  disconnect() {
    this.desktop.removeEventListener("change", this.resize)
  }

  toggle() {
    const open = this.toggleTarget.getAttribute("aria-expanded") !== "true"
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.linksTarget.hidden = !open
  }

  close() {
    if (this.desktop.matches || this.linksTarget.hidden) return
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.linksTarget.hidden = true
    this.toggleTarget.focus()
  }

  reset() {
    const focusedLink = this.linksTarget.contains(document.activeElement)
    const focusedToggle = document.activeElement === this.toggleTarget
    this.toggleTarget.hidden = this.desktop.matches
    this.linksTarget.hidden = !this.desktop.matches
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (!this.desktop.matches && focusedLink) this.toggleTarget.focus()
    if (this.desktop.matches && focusedToggle) this.linksTarget.querySelector("a")?.focus()
  }
}
