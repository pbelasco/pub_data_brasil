#!/usr/bin/ruby
require 'rubygems'
require 'hpricot'
require 'curb'
require "iconv"

# recebe Input e retorna parsed_vars ou false em caso de erro
def parse_input(args)
  
  parsed_vars = []
  if args[0].to_s.include?('id=')
    puts "ok, começando..."
    parsed_vars << args[0].split("=")[1]
    parsed_vars
  elsif args[0].include?('range=')
    puts "ok, começando..."
    range=args[0].split("=")[1]
    puts "range = #{range}"
    Proposicao.find(:all, :limit => range).each {|p| parsed_vars << p.id_sileg }
    parsed_vars
  else 
    puts "Modo de uso 'scrap_propositions_detalhes.rb <id=<id_sileg> | range=<primeira>,<range>>'"
    puts "Exemplo:"
    puts "Carrega as informacoes da proposicao: "
    puts "$script/runner scrap_propositions_detalhes.rb id=21424124"
    puts "$script/runner scrap_propositions_detalhes.rb range=0,10"
    puts "pbelasco 2009"
    puts "GPLv3"
    nil
  end
end

def make_url(var)
  url = "http://www.camara.gov.br/sileg/Prop_Detalhe.asp?id=#{var}"
end

# recebe url e devolve hpricot parsed doc string
# recebe url e devolve hpricot parsed doc string
def get_parsed_page(url)
  
  c = Curl::Easy.new("#{url}") do |curl|
    curl.headers["User-Agent"] = "pub_data client v.001Beta Ruby"
    curl.verbose = true
    curl.verbose = false
  end
  puts "tentando obter resultado de #{url}"
  
  c = perform_req(c)
  # cuida do encoding
  enc = Iconv.new('UTF-8', 'ISO-8859-1')
  
  doc = Hpricot.parse( enc.iconv(c.body_str), :fixup_tags => true )
  # puts doc.html
  doc
end

# Método recursivo para realizar requisição dados do servidor
def perform_req(curl_obj)
  c = curl_obj
  
  begin 
    c.perform
    if c.response_code != 200 
      puts "código de resposta: #{c.response_code}"
      puts "aguardando 1 segundos para tentar novamente..."
      sleep 1
      c = perform_req(curl_obj)
    else 
      return c # Condição de parada na pilha
    end
  rescue Exception => e
    puts e.inspect
    puts "erro no servidor, devolvendo nulo"
    puts "aguardando 1 segundos para tentar novamente..."
    sleep 1
    return perform_req(c)
  rescue NoMethodError => e
    puts "erro no programa... matando a pau... ratatatata tatatata..."
    nil
  end
end

def get_the_andamento_rows(doc)
  # Tabela que contem os elementos de andamento
  puts "selecionando andamentos..."
  rows = (doc/"//table//table//table//tr")
  # Elimina o cabeçalho
  rows.shift
  puts "encontrei #{rows.size} andamentos"
  # puts rows.html
  rows
end

def parse_tags(doc)
  tags = doc.html.split(/[Indexa][^o ]*o: <\/b>/)[1].split("<b>")[0].strip || nil
  inspect_tags(tags)
end
def parse_prop_detalhes(doc)
  puts "começando parsing dos andamentos..."
  prop_detalhes = []
  h = Hash.new("Este andamento")  
  unless doc.nil?
    h[:media_link] = (doc/"/html/body/table//tr[2]/td[2]/a").to_s.map { |s| s.split("HREF=\"")[1].split("\" ")[0] || nil } 
    h[:id_sileg] = ARGV[0].to_i
    # link que contem o id e o cod/ano da proposicao
    unless (doc/"/html/body/table//tr[2]/td/p").empty?
      h[:explicacao] =  (doc/"/html/body/table//tr[2]/td/p").html.split(/[Explica][^o ]*o da Ementa: <\/b>/)[1].split("<b>")[0].strip || nil
      h[:apreciacao] =  (doc/"/html/body/table//tr[2]/td/p").html.split(/[Aprecia][^o ]*o: <\/b>/)[1].split("<b>")[0].strip || nil
      h[:tramitacao] =  (doc/"/html/body/table//tr[2]/td/p").html.split(/[Regime de tramita][^o ]*o: <\/b>/)[1].split("<b>")[0].strip || nil
      h[:despacho]   =  (doc/"/html/body/table//tr[2]/td/p").html.split(/[Despacho :]: <\/b>/)[1].split("<b>")[0].strip || nil 
    end
    puts "#{h.inspect}\nDetalhes de Proposta ----------------------------------------" unless h.empty?
    
    # Cria/atualiza prop
    h
  end
end
def parse_andamentos(rows)
  puts "começando parsing dos andamentos..."
  andamentos = []
  rows.each do |row| 
    unless row.empty? 
      # link que contem o id e o cod/ano da proposicao
      h = Hash.new("Este andamento")  
      h[:local] = (row/"b").first.inner_html.to_s.strip.split("&nbsp;").join(" ").gsub(/(\r\n)|\t/, "") || nil
      h[:data] = (row/"td")[0].inner_html.strip.split("/").reverse.join("-") || nil
      h[:descricao]  = (row/"td[2]//")[5].to_s.strip || nil   
      h[:media_link] = (row/'a[@HREF]').to_s.map { |s| s.split("HREF=\"")[1].split("\" ")[0] || nil }
      h[:id_sileg] = ARGV[0].to_i
       
      puts "#{h.inspect}\nAndamento --------------------------------------------------" unless row.empty?
      andamentos << h
    end 
  end   
  puts "criados/atualizados #{andamentos.size} registros"
  andamentos
end

def inspect_detalhes(h)
  h.inspect
end

def create_or_update_prop_batch(h)
  h.each do |ha|
    create_or_update_prop(:id_sileg, ha)
  end
end

def create_or_update_prop(field, h)
  Proposicao.create_or_update_by(field, h)
end

# Resolver modo de keep_track do andamento
def create_or_update_andamento_batch(prop, h)
  h.each do |ha|
    create_or_update_andamento(:id_sileg, ha)
  end
end

def create_or_update_andamentos(fields, andamentos, prop)
  prop.andamentos.each {|a| a.destroy}
  andamentos.each do |h|
    a = Andamento.create_or_update_by_multiple(fields, h)
    prop.andamentos << a
  end
end

def create_or_update_tags(prop, tags_str, field = :termo)
  prop.taggeds.each {|tagged| tagged.destroy}
  tags_str.split(",").each do |t|
    unless t.strip.match("^[_].*") 
      tag = Tag.create_or_update_by(field, {:termo => t}) 
      prop.tags << tag 
    end
  end unless tags_str.nil?
end

def inspect_tags(tags_str = "")
  
  tags_str.split(",").each do |t|
    puts t.strip unless t.strip.match("^[_].*") 
  end
  puts "Tags   --------------------------------------------------" 
  
end

parsed_input = parse_input(ARGV)
puts parsed_input.inspect
unless parsed_input.empty? 
  parsed_input.each do |id|
    url = make_url(id)
    parsed_page = get_parsed_page(url)

    prop_desc = parse_prop_detalhes(parsed_page)
    prop = create_or_update_prop(:id_sileg, prop_desc)

    tags_desc = parse_tags(parsed_page)
    create_or_update_tags(prop, tags_desc, :termo)

    andamento_desc = get_the_andamento_rows(parsed_page)
    andamentos = parse_andamentos(andamento_desc)
    create_or_update_andamentos([:id_sileg, :data, :local, :descricao, :media_link], andamentos, prop)
  end  
end