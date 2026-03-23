class RemoveDuplicateDurationColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :services, :duration, :integer
  end
end
