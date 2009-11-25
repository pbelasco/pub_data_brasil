class ProposicaosController < ApplicationController
  # GET /proposicaos
  # GET /proposicaos.xml
  
  layout '1col'
  
  def index
   
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
    unless params[:q].blank?
      params[:page] = 1 unless params[:page]
      
      @proposicaos = Proposicao.find_by_solr("#{params[:q]}", {:limit => 10, :offset => params[:page], :order => 'apresentacao desc' })
      
      @proposicaos.docs.each do |p| 
        if p.ellegible_for_update 
          Delayed::Job.enqueue(UpdateCamaraProposition.new( p.id_sileg), 0) 
        end
      end
      
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
    @proposicao = Proposicao.find_by_id_sileg(params[:id], :include => :andamentos)
    if @proposicao.ellegible_for_update 
      flash[:notice] = "A proposição que você está visualizando pode não estar atualizada. Uma atualização do conteúdo já foi agendada..."
      Delayed::Job.enqueue(UpdateCamaraProposition.new(params[:id]), 1)
    end
    
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

  # GET /proposicaos/new
  # GET /proposicaos/new.xml
  # def new
  #   @proposicao = Proposicao.new
  # 
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @proposicao }
  #     format.json { render :json => @proposicao.to_json }
  #     format.yaml { render :yaml => @proposicao.to_yaml }
  #     
  #   end
  # end

  # GET /proposicaos/1/edit
  # def edit
  #   @proposicao = Proposicao.find(params[:id])
  # end

  # POST /proposicaos
  # POST /proposicaos.xml
  # def create
  #   @proposicao = Proposicao.new(params[:proposicao])
  # 
  #   respond_to do |format|
  #     if @proposicao.save
  #       flash[:notice] = 'Proposicao was successfully created.'
  #       format.html { redirect_to(@proposicao) }
  #       format.xml  { render :xml => @proposicao, :status => :created, :location => @proposicao }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @proposicao.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # PUT /proposicaos/1
  # PUT /proposicaos/1.xml
  # def update
  #   @proposicao = Proposicao.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @proposicao.update_attributes(params[:proposicao])
  #       flash[:notice] = 'Proposicao was successfully updated.'
  #       format.html { redirect_to(@proposicao) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @proposicao.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /proposicaos/1
  # DELETE /proposicaos/1.xml
  # def destroy
  #   @proposicao = Proposicao.find(params[:id])
  #   @proposicao.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(proposicaos_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
