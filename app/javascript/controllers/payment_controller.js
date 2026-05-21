import { Controller } from "@hotwired/stimulus"
import { loadMercadoPago } from "@mercadopago/sdk-js"

export default class extends Controller {
  static targets = ["container"]

  async connect() {
    await loadMercadoPago()

    // Recupera a chave pública que colocamos no meta tag
    const publicKey = document.querySelector("meta[name='mp-public-key']").getAttribute("content")

    const mp = new window.MercadoPago(publicKey, { locale: 'pt-BR' })
    const bricksBuilder = mp.bricks()

    this.renderBrick(bricksBuilder)
  }

  async renderBrick(bricksBuilder) {
    const settings = {
      initialization: {
        amount: 50.00, // Valor do sinal fictício por enquanto
        preferenceId: null, // Não obrigatório para Bricks transparente
      },
      customization: {
        visual: {
          style: {
            theme: "default", // Combina bem com qualquer design clean
          },
        },
        paymentMethods: {
          creditCard: "all",
          debitCard: "all",
          pix: "all", // O foco do nosso SaaS em BH
        },
      },
      callbacks: {
        onReady: () => {
          console.log("Brick do Mercado Pago pronto.")
        },
        onSubmit: ({ selectedPaymentMethod, formData }) => {
          console.log("Enviando dados para o Rails:", formData)

          return new Promise((resolve, reject) => {
            fetch("/payments", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              // Envelopamos o formData na chave 'payment' para casar com o strong_params do Rails
              body: JSON.stringify({ payment: formData })
            })
            .then((response) => response.json())
            .then((data) => {
              if (data.status === 'approved' || data.status === 'pending') {
                // 'pending' é o status normal para Pix aguardando pagamento
                resolve()
                console.log("Resposta do MP:", data)
                alert("Sucesso! Pagamento registrado. (Olhe o console para ver o payload do Pix)")
              } else {
                reject()
                console.error("Pagamento recusado:", data)
                alert("Erro ao processar o pagamento.")
              }
            })
            .catch((error) => {
              reject()
              console.error("Falha na comunicação com o servidor:", error)
              alert("Erro de comunicação.")
            })
          })
        },
        onError: (error) => {
          console.error("Erro no Brick:", error)
        },
      },
    }

    window.paymentBrickController = await bricksBuilder.create(
      "payment",
      "paymentBrick_container",
      settings
    )
  }
}
