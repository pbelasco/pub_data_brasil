ActionController::Routing::Routes.draw do |map|
  map.resources :user_sessions

  map.resources :users

  map.resources :paginas

  map.login "login", :controller => "user_sessions", :action => 'new'
  map.login "logout", :controller => "user_sessions", :action => 'destroy'
  map.search_proposicaos 'proposicoes/busca', :controller => 'proposicaos', :action => 'search', :method => :get
  map.get_search_proposicaos 'proposicoes/busca/:format/:q', :controller => 'proposicaos', :action => 'search', :method => :get
  map.get_descreve_proposicaos 'proposicoes/descricao/:format', :controller => 'proposicaos', :action => 'descricao', :method => :get
  map.resources :proposicaos, :as => "proposicoes"

  map.root :controller => 'paginas', :action => 'index'
end
