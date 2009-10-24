class ProposicaosController < ApplicationController
  # GET /proposicaos
  # GET /proposicaos.xml
  def index
    order = "id DESC" || params[:order]
    sort  = "DESC" || params[:sort]
    @num_proposicaos = Proposicao.count(:all)
    @proposicaos = Proposicao.find(:all, :order => "'#{order} #{sort}'", :page => {:size => 10, :current => params[:page], :first => 1})
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @proposicaos }
    end
  end

  def search
    unless params[:q].blank?
      # params[:q] = sanitize(params[:q])
      params[:p] = 1 unless params[:p]
      @proposicaos = Proposicao.paginating_ferret_search({:q => "#{params[:q]}~0.4", :page_size => 10, :current => params[:p]})
      @total_hits = Proposicao.find_with_ferret("#{params[:q]}~", :lazy => true).total_hits
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @proposicaos }
      end
    else
      flash[:warning] = "Por favor informe uma chave de pesquisa"
      redirect_to proposicaos_path
    end
  end

  # GET /proposicaos/1
  # GET /proposicaos/1.xml
  def show
    @proposicao = Proposicao.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @proposicao }
    end
  end

  # GET /proposicaos/new
  # GET /proposicaos/new.xml
  def new
    @proposicao = Proposicao.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @proposicao }
    end
  end

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
