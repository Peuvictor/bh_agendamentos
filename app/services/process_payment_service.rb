class ProcessPaymentService
  def self.call(payment_data)
    # O SDK do Mercado Pago faz a requisição para a API
    response = $mp.payment.create(payment_data.to_h)

    # 201 Created ou 200 OK
    if response[:status] == 201 || response[:status] == 200
      { success: true, payload: response[:response] }
    else
      Rails.logger.error("Falha no MP: #{response[:response]}")
      { success: false, error: response[:response] }
    end
  end
end
