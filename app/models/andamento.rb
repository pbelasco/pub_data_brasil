class Andamento < ActiveRecord::Base
  belongs_to :proposicao
  has_many :anexos
end
