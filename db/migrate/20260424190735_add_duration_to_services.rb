class AddDurationToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :duration, :integer
  end
end
