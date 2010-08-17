class TrendsController < ApplicationController
  layout 'charts'
  def index
    
  end
  def compare
    if params[:t1] && params[:t2]
      
      arr1 = Proposicao.search(params[:t1], :per_page => 1000).map {|r| [r.apresentacao.year] if r.apresentacao}.compact.sort
      arr2 = Proposicao.search(params[:t2], :per_page => 1000).map {|r| [r.apresentacao.year] if r.apresentacao}.compact.sort
      @r1 = arr1.inject(Hash.new(0)) {|h,e| h[e]+= 1; h}
      @r2 = arr2.inject(Hash.new(0)) {|h,e| h[e]+= 1; h}
      @r_all = @r1.to_a.each{|a1| a1 << @r2[a1[0]] || 0}.sort.map{|r| [r[0].to_s, r[1], r[2]]}
      
      @text = "Comparação dos termos"
    else
      @text = "Informe dois termos para comparação"
    end
  end
  private
end
