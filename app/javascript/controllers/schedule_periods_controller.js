import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["periods", "template", "period", "label"]

  static values = {
    nextIndex: Number
  }

  add() {
    const index = this.nextIndexValue
    const fields = this.templateTarget.innerHTML.replaceAll("NEW_INDEX", index)

    this.periodsTarget.insertAdjacentHTML("beforeend", fields)
    this.nextIndexValue = index + 1
    this.renumber()
  }

  remove(event) {
    event.currentTarget.closest("[data-schedule-periods-target='period']")?.remove()
    this.renumber()
  }

  renumber() {
    this.periodTargets.forEach((period, index) => {
      const number = index + 1
      const label = period.querySelector("[data-schedule-periods-target='label']")
      const startInput = period.querySelector("[data-role='start']")
      const endInput = period.querySelector("[data-role='end']")

      if (label) label.textContent = `Turno ${number}`
      if (startInput) startInput.setAttribute("aria-label", `Início do turno ${number}`)
      if (endInput) endInput.setAttribute("aria-label", `Fim do turno ${number}`)
    })
  }
}
