class AddAutorLinkToProposicao < ActiveRecord::Migration
  def self.up
    add_column :proposicaos, :autor_link, :string
  end

  def self.down
    remove_column :proposicaos, :autor_link
  end
end
