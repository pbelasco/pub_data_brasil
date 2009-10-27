class AddFieldsToProposicao < ActiveRecord::Migration
  def self.up
    add_column :proposicaos, :media_link, :string
    add_column :proposicaos, :explicacao, :text
    add_column :proposicaos, :apreciacao, :text
    add_column :proposicaos, :tramitacao, :text
  end

  def self.down
    remove_column :proposicaos, :tramitacao
    remove_column :proposicaos, :apreciacao
    remove_column :proposicaos, :explicacao
    remove_column :proposicaos, :media_link
  end
end
