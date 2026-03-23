class RefineAppointmentsAndServices < ActiveRecord::Migration[7.1]
  def change
    # Adiciona duração ao serviço se não existir
    add_column :services, :duration, :integer, default: 30 unless column_exists?(:services, :duration)

    # Adiciona o fim do agendamento se não existir
    add_column :appointments, :end_time, :datetime unless column_exists?(:appointments, :end_time)

    # Índice para performance em buscas de agenda
    add_index :appointments, [:start_time, :end_time] unless index_exists?(:appointments, [:start_time, :end_time])
  end
end
