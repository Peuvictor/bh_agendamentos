# frozen_string_literal: true

module Demo
  module Records
    def self.id(key)
      Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "bh-agendamentos/demo/v1/#{key}")
    end

    def self.create(model, key, attributes)
      model.find_by(id: id(key)) || model.create!(attributes.merge(id: id(key)))
    end
  end
end
