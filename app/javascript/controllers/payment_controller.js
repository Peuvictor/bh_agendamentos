import { Controller } from "@hotwired/stimulus"
import { loadMercadoPago } from "@mercadopago/sdk-js"

export default class extends Controller {
  static targets = ["container"]
  // 1. BLINDAGEM: Variáveis dinâmicas que receberemos da view (HTML)
  static values = {
    appointmentId: String,
    amount: Number
  }

  async connect() {
    await loadMercadoPago()

    const publicKey = document.querySelector("meta[name='mp-public-key']").getAttribute("content")
    const mp = new window.MercadoPago(publicKey, { locale: 'pt-BR' })
    const bricksBuilder = mp.bricks()

    this.renderBrick(bricksBuilder)
  }

  async renderBrick(bricksBuilder) {
    const settings = {
      initialization: {
        // 2. Agora o valor visual vem do banco de dados, e não é mais chumbado no JS
        amount: this.amountValue,
        preferenceId: null,
      },
      customization: {
        visual: { style: { theme: "default" } },
        paymentMethods: {
          creditCard: "all",
          debitCard: "all",
          pix: "all",
        },
      },
      callbacks: {
        onReady: () => {
          console.log("Brick do Mercado Pago pronto.")
        },
        onSubmit: ({ selectedPaymentMethod, formData }) => {
          return new Promise((resolve, reject) => {
            const csrfToken = document.querySelector("meta[name='csrf-token']").content

            fetch("/payments", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
              },
              // 3. ENVIO SEGURO: Mandamos o ID do agendamento junto com os dados do cartão
              body: JSON.stringify({
                appointment_id: this.appointmentIdValue,
                payment: formData
              })
            })
            .then((response) => response.json())
            .then((data) => {
              if (data.status === 'approved' || data.status === 'pending') {
                resolve()
                const container = document.getElementById("paymentBrick_container")

                if (selectedPaymentMethod === 'pix') {
                  // O PIX precisa dos dados detalhados para montar o QR Code
                  const pixData = data.detail.point_of_interaction.transaction_data
                  const pixCopiaECola = pixData.qr_code
                  const pixQrCodeBase64 = pixData.qr_code_base64

                  container.innerHTML = `
                    <div class="text-center p-6 bg-white rounded-xl border border-blue-100 shadow-sm">
                      <h3 class="text-xl font-bold text-slate-800 mb-4">Escaneie o QR Code</h3>
                      <img src="data:image/jpeg;base64,${pixQrCodeBase64}" alt="QR Code Pix" class="mx-auto w-48 h-48 mb-4 border rounded-lg">
                      <p class="text-sm font-bold text-slate-500 mb-2">Ou use o Pix Copia e Cola:</p>
                      <input type="text" value="${pixCopiaECola}" readonly
                             class="w-full text-xs font-mono p-3 border rounded-lg bg-slate-50 cursor-pointer hover:bg-slate-100 transition"
                             onclick="navigator.clipboard.writeText(this.value); alert('Chave Pix copiada, uai!')">
                      <p class="text-xs text-slate-400 mt-4">Aguardando confirmação do pagamento...</p>
                    </div>
                  `
                } else {
                  container.innerHTML = `
                    <div class="p-6 text-center text-green-600 font-bold bg-green-50 rounded-xl border border-green-200">
                      Pagamento processado com sucesso!
                    </div>
                  `
                }
              } else {
                reject()
                alert(`Erro: ${data.error || 'Pagamento recusado'}`)
              }
            })
            .catch((error) => {
              reject()
              alert("Erro de comunicação com o servidor.")
            })
          })
        },
      },
    }

    window.paymentBrickController = await bricksBuilder.create("payment", "paymentBrick_container", settings)
  }
}
