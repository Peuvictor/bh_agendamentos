import { Controller } from "@hotwired/stimulus"
import { loadMercadoPago } from "@mercadopago/sdk-js"

export default class extends Controller {
  static targets = ["container", "feedback"]

  static values = {
    appointmentId: String,
    amount: Number
  }

  async connect() {
    this.connected = true
    const publicKey = document.querySelector("meta[name='mp-public-key']")?.content?.trim()

    if (!publicKey) {
      this.showInitializationError("Pagamento temporariamente indisponível. A chave pública do Mercado Pago não foi configurada.")
      return
    }

    try {
      await loadMercadoPago()
      if (!this.connected) return

      if (typeof window.MercadoPago !== "function") {
        throw new Error("MercadoPago.js não está disponível")
      }

      const mercadoPago = new window.MercadoPago(publicKey, { locale: "pt-BR" })
      await this.renderBrick(mercadoPago.bricks())
    } catch (error) {
      console.error("Falha ao inicializar o Mercado Pago", error)
      this.showInitializationError("Não foi possível carregar o checkout. Atualize a página ou tente novamente mais tarde.")
    }
  }

  disconnect() {
    this.connected = false
    this.brickController?.unmount()
    this.brickController = null
  }

  async renderBrick(bricksBuilder) {
    const settings = {
      initialization: {
        amount: this.amountValue,
        preferenceId: null
      },
      customization: {
        visual: { style: { theme: "default" } },
        paymentMethods: {
          creditCard: "all",
          debitCard: "all",
          bankTransfer: "pix",
        },
      },
      callbacks: {
        onReady: () => {
          this.clearFeedback()
        },
        onError: (error) => {
          console.error("Erro no Payment Brick", error)
          this.showFeedback("O checkout encontrou um erro. Revise os dados ou tente novamente.")
        },
        onSubmit: ({ selectedPaymentMethod, formData }) => this.submitPayment(selectedPaymentMethod, formData)
      }
    }

    this.brickController = await bricksBuilder.create("payment", this.containerTarget.id, settings)
  }

  async submitPayment(selectedPaymentMethod, formData) {
    this.clearFeedback()

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch("/payments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          appointment_id: this.appointmentIdValue,
          payment: formData
        })
      })
      const data = await response.json().catch(() => ({}))

      if (!response.ok || !["approved", "pending"].includes(data.status)) {
        throw new Error(data.error || "Pagamento não autorizado. Revise os dados e tente novamente.")
      }

      if (selectedPaymentMethod === "pix") {
        this.renderPix(data)
      } else {
        this.renderApprovedPayment()
      }
    } catch (error) {
      this.showFeedback(error.message || "Erro de comunicação com o servidor. Tente novamente.")
      throw error
    }
  }

  renderPix(data) {
    const pixData = data.detail?.point_of_interaction?.transaction_data

    if (!pixData?.qr_code || !pixData?.qr_code_base64) {
      throw new Error("O PIX foi criado, mas o QR Code não foi recebido. Consulte seus agendamentos antes de tentar novamente.")
    }

    this.containerTarget.innerHTML = `
      <div class="text-center p-6 bg-white rounded-xl border border-blue-100 shadow-sm">
        <h3 class="text-xl font-bold text-slate-800 mb-4">Escaneie o QR Code</h3>
        <img data-role="pix-image" alt="QR Code Pix" class="mx-auto w-48 h-48 mb-4 border rounded-lg">
        <p class="text-sm font-bold text-slate-500 mb-2">Ou use o Pix Copia e Cola:</p>
        <input data-role="pix-code" type="text" readonly class="w-full text-xs font-mono p-3 border rounded-lg bg-slate-50">
        <button data-role="copy-pix" type="button" class="mt-3 text-sm font-bold text-blue-700 hover:text-blue-900">Copiar código Pix</button>
        <p class="text-xs text-slate-400 mt-4">Aguardando confirmação do pagamento...</p>
      </div>
    `

    this.containerTarget.querySelector("[data-role='pix-image']").src = `data:image/jpeg;base64,${pixData.qr_code_base64}`
    this.containerTarget.querySelector("[data-role='pix-code']").value = pixData.qr_code
    this.containerTarget.querySelector("[data-role='copy-pix']").addEventListener("click", () => this.copyPixCode(pixData.qr_code))
  }

  renderApprovedPayment() {
    this.containerTarget.innerHTML = `
      <div class="p-6 text-center text-green-700 font-bold bg-green-50 rounded-xl border border-green-200">
        Pagamento aprovado! Seu agendamento está confirmado.
      </div>
    `
  }

  async copyPixCode(code) {
    try {
      await navigator.clipboard.writeText(code)
      this.showFeedback("Código Pix copiado.", "success")
    } catch (error) {
      console.error("Falha ao copiar o código Pix", error)
      this.showFeedback("Não foi possível copiar automaticamente. Selecione o código acima e copie manualmente.")
    }
  }

  showInitializationError(message) {
    this.containerTarget.replaceChildren()
    this.showFeedback(message)
  }

  showFeedback(message, type = "error") {
    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.toggle("border-red-200", type === "error")
    this.feedbackTarget.classList.toggle("bg-red-50", type === "error")
    this.feedbackTarget.classList.toggle("text-red-700", type === "error")
    this.feedbackTarget.classList.toggle("border-green-200", type === "success")
    this.feedbackTarget.classList.toggle("bg-green-50", type === "success")
    this.feedbackTarget.classList.toggle("text-green-700", type === "success")
    this.feedbackTarget.classList.remove("hidden")
  }

  clearFeedback() {
    this.feedbackTarget.textContent = ""
    this.feedbackTarget.classList.add("hidden")
  }
}
