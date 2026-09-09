import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "hour", "feedback"]
  static values = { url: String }

  disconnect() {
    this.request?.abort()
  }

  async refresh() {
    this.request?.abort()
    const request = new AbortController()
    this.request = request
    this.feedbackTarget.textContent = ""
    this.hourTarget.disabled = true
    this.hourTarget.replaceChildren(new Option("Carregando horários...", ""))
    if (!this.dateTarget.value) {
      this.hourTarget.replaceChildren(new Option("Escolha uma data", ""))
      return
    }

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("date", this.dateTarget.value)
      const response = await fetch(url, { signal: request.signal, headers: { Accept: "application/json" } })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Não foi possível consultar os horários.")
      if (this.request !== request) return
      this.hourTarget.replaceChildren(new Option(data.slots.length ? "Selecione um horário" : "Nenhum horário disponível", ""))
      data.slots.forEach(slot => this.hourTarget.add(new Option(slot, slot)))
    } catch (error) {
      if (request.signal.aborted || this.request !== request) return
      this.hourTarget.replaceChildren(new Option("Erro ao carregar horários", ""))
      this.feedbackTarget.textContent = "Não foi possível consultar os horários. Selecione a data novamente para tentar."
    } finally {
      if (this.request === request && !request.signal.aborted) this.hourTarget.disabled = false
    }
  }
}
