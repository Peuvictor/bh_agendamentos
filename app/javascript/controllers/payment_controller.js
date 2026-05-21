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
          // Aqui o front-end coletou os dados seguros e gerou o token.
          // O Don cuidará de enviar isso via Fetch para o Rails no próximo passo.
          console.log("Dados capturados com segurança:", formData)
          return new Promise((resolve, reject) => {
            // Próxima etapa: Enviar formData para o backend
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
