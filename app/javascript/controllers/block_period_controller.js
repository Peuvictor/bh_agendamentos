import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["allDay", "times"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.timesTarget.disabled = this.allDayTarget.checked
    this.timesTarget.classList.toggle("opacity-50", this.allDayTarget.checked)
  }
}
