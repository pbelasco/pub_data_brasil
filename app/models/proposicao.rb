class Proposicao < ActiveRecord::Base

  has_many :andamentos
  has_many :taggeds
  has_many :tags, :through => :taggeds

  define_index do
    indexes autor
    indexes id_sileg
    indexes ementa
    indexes apresentacao
    indexes despacho
    indexes apreciacao
    indexes descricao, :sortable => true
    
    has :created_at, :updated_at
  end
  
  def ellegible_for_update
    self.created_at == self.updated_at || self.updated_at < Time.now - 7.day  
  end

end
