class CreateProposicaos < ActiveRecord::Migration
  def self.up
    create_table :proposicaos do |t|
      t.integer :id_sileg
      t.string  :descricao
      t.string :link      
      t.string :orgao
      t.string :autor
      t.date :apresentacao
      t.text :ementa
      t.text :despacho
      t.text :situacao  
      t.timestamps
    end
    # execute "alter table proposicaos modify column id_sileg bigint unsigned primary key"
    
  end

  def self.down
    drop_table :proposicaos
  end
end
