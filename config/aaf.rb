# require 'rubygems'
# require 'ferret'
# 
# module Ferret::Analysis
#   class MyAnalyzer 
#     def token_stream(field, str)
#       return StemFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), "portuguese")
#     end
#   end
# end
# 
# ActsAsFerret::define_index('shared',
#  :models => {
#    Proposicao   => {:fields => [:id_sileg, :descricao, :link, :orgao, :autor, :apresentacao, :ementa, :despacho]}
#  },
#  :ferret   => {:analyzer =>  Ferret::Analysis::MyAnalyzer.new()})