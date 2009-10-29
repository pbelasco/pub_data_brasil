class Proposicao < ActiveRecord::Base

  has_many :andamentos
  has_many :taggeds
  has_many :tags, :through => :taggeds


  define_index do
    indexes autor
    indexes ementa
    indexes descricao, :sortable => true
  dend

  # acts_as_ferret :fields => {
  #   :autor => {:boost => 3},
  #   :ementa => {:boost => 2},
  #   :orgao => {:boost => 1},
  #   :descricao=> {:boost => 3}
  # }
  
  def self.paginating_ferret_search(options)
    count = self.find_with_ferret(options[:q], {:lazy => true}).total_hits
    PagingEnumerator.new(options[:page_size], count, false, options[:current], 1) do |page|
      offset = (options[:current].to_i - 1) * options[:page_size]
      limit = options[:page_size]
      res = self.find_with_ferret(options[:q], {:offset => offset, :limit => limit})
    end
  end

end
