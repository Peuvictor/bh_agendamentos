import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]

  connect() {
    // Define o valor inicial (padrão 5)
    this.currentValue = this.inputTarget.value || 5
    this.updateStars(this.currentValue)
  }

  hover(event) {
    const value = event.currentTarget.dataset.value
    this.updateStars(value)
  }

  leave() {
    // Quando o mouse sai, volta para a nota fixada no click
    this.updateStars(this.currentValue)
  }

  select(event) {
    // Crava a nota clicada e atualiza o campo oculto do Rails
    this.currentValue = event.currentTarget.dataset.value
    this.inputTarget.value = this.currentValue
    this.updateStars(this.currentValue)
  }

  updateStars(rating) {
    this.starTargets.forEach((star) => {
      if (parseInt(star.dataset.value) <= parseInt(rating)) {
        star.classList.remove("text-gray-300")
        star.classList.add("text-yellow-400")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-gray-300")
      }
    })
  }
}
