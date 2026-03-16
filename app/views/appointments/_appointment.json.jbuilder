json.extract! appointment, :id, :client_id, :service_id, :start_time, :end_time, :status, :created_at, :updated_at
json.url appointment_url(appointment, format: :json)
