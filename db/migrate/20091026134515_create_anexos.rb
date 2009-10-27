class CreateAnexos < ActiveRecord::Migration
  def self.up
    create_table :anexos do |t|
      t.string :titulo
      t.references :andamento
      t.references :poposicao

      t.timestamps
    end
  end

  def self.down
    drop_table :anexos
  end
end
