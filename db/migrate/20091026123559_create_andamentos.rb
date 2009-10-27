class CreateAndamentos < ActiveRecord::Migration
  def self.up
    create_table :andamentos do |t|
      t.references :proposicao
      t.date :data
      t.text :titulo
      t.text :descricao
      t.references :anexo

      t.timestamps
    end
  end

  def self.down
    drop_table :andamentos
  end
end
