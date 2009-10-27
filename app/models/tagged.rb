class Tagged < ActiveRecord::Base
  belongs_to :tag
  belongs_to :proposicao
end
