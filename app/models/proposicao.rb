class Proposicao < ActiveRecord::Base

  has_many :andamentos
  has_many :taggeds
  has_many :tags, :through => :taggeds

  acts_as_solr :fields => [:autor, :id_sileg, :ementa, :apresentacao, :despacho, :apreciacao, :descricao]
  
  def ellegible_for_update
    self.created_at == self.updated_at || self.updated_at < Time.now - 7.day  
  end

end
