class AddAcessoriaDeToProposicao < ActiveRecord::Migration
  def self.up
    add_column :proposicaos, :acessoria_de, :string
  end

  def self.down
    remove_column :proposicaos, :acessoria_de
  end
end
