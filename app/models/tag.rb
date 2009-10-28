class Tag < ActiveRecord::Base
  has_many :taggeds
  has_many :proposicaos, :through => :taggeds
end
