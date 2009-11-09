class Pagina < ActiveRecord::Base
  validates_presence_of :titulo, :message => "não pode ser vazio"  
end
