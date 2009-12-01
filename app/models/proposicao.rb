class Proposicao < ActiveRecord::Base

  has_many :andamentos
  has_many :taggeds
  has_many :tags, :through => :taggeds
  
  has_many :apensas, :foreign_key => :apensada
  belongs_to :apensas, :foreign_key => :original

  has_many :proposicaos, :through => :apensas, :foreign_key => :apensada, :as => :apensadas
  # belongs_to :proposicao, :through => :apensa, :foreign_key => :apensada

  acts_as_solr :fields => [:autor, :id_sileg, :ementa, :apresentacao, :despacho, :apreciacao, :descricao]
  
  def ellegible_for_update
    #self.created_at == self.updated_at || self.updated_at < Time.now - 7.day
    self.updated_at < Time.now - 7.day
  end

end
