# frozen_string_literal: true

module Demo
  module Payments
    def self.create(appointment, key)
      Records.create(Payment, "payment/#{key}",
                     appointment: appointment, amount: appointment.service.preco,
                     status: appointment.reembolsado? ? :reembolsado : :aprovado,
                     refunded_at: appointment.refunded_at,
                     mp_transaction_id: "demo-#{appointment.id}", idempotency_key: "demo-#{appointment.id}")
    end
  end
end
