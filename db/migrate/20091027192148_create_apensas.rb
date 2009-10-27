class CreateApensas < ActiveRecord::Migration
  def self.up
    create_table :apensas do |t|
      t.integer :original
      t.integer :apensada

      t.timestamps
    end
  end

  def self.down
    drop_table :apensas
  end
end
