class ProposicaosController < ApplicationController
  # GET /proposicaos
  # GET /proposicaos.xml
  
  layout '1col'
  
  def index
    sort = case params['sort']
              when "data"   then "apresentacao DESC"
              when "data_reverse" then "apresentacao ASC"
                
              when "name_reverse"  then "name DESC"
              when "qty_reverse"   then "quantity DESC"
              when "price_reverse" then "price DESC"
    end
              
    @num_proposicaos = Proposicao.count(:all)
    @proposicaos = Proposicao.paginate(:page => params[:page], :per_page => 10, :order => 'apresentacao DESC', :include => :andamentos)
    @proposicaos.each do |p| 
      if p.ellegible_for_update 
        Delayed::Job.enqueue(UpdateCamaraProposition.new( p.id_sileg), 0) 
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @proposicaos }
      format.json { render :json => @proposicaos.to_json }
      format.yaml { render :inline => [@proposicaos.to_yaml, @proposicaos.docs.map {|p| p.to_yaml}] }
    end
  end

  def search
    require 'extended_string'
    
    unless params[:q].blank?
      params[:page] = 1 unless params[:page]
      
      @proposicaos = Proposicao.find_by_solr("#{params[:q].strip_diacritics}", {:limit => 10, :offset => params[:page] })
      
      
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @proposicaos.docs }
        format.json { render :json =>  [@proposicao.to_json, @proposicaos.docs.map {|p| p.to_json}] }
        format.yaml { render :inline =>  [@proposicao.to_yaml, @proposicaos.docs.map {|p| p.to_yaml}] }
      end
    else
      flash[:notice] = "Por favor informe uma chave de pesquisa"
      redirect_to proposicaos_path
    end
  end

  # GET /proposicaos/1
  # GET /proposicaos/1.xml
  def show
    @proposicao = Proposicao.find(params[:id], :include => :andamentos)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => [@proposicao] }
      format.json { render :json => @proposicao.to_json }
      format.yaml { render :inline => @proposicao.to_yaml }
      
    end
  end
  
  def descricao
    # @proposicao = Proposicao.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => Proposicao.new.class }
      format.json { render :json => Proposicao.inspect.to_json }
      format.yaml { render :inline => Proposicao.inspect.to_yaml }
      
    end
  end
end
