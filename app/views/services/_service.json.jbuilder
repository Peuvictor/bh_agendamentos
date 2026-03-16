json.extract! service, :id, :nome, :descricao, :duracao_minutos, :preco, :user_id, :created_at, :updated_at
json.url service_url(service, format: :json)
