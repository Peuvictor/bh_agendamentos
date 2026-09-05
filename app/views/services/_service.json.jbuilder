json.extract! service, :id, :nome, :descricao, :duration, :preco, :user_id, :archived_at, :archived_by_admin,
              :created_at, :updated_at
json.url service_url(service, format: :json)
