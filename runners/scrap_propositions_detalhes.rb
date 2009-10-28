#!/usr/bin/ruby
require 'rubygems'
require 'hpricot'
require 'curb'
require "iconv"

# recebe Input e retorna parsed_vars ou false em caso de erro
def parse_input(args)
  case args
  when args.size < 1
    puts "Modo de uso 'scrap_propositions_detalhes.rb < id_sileg >"
    puts "Exemplo"
    puts "Carrega as informacoes da proposicao: "
    puts "exemplo"
    puts "$script/runner scrap_propositions_detalhes.rb '164323'"
    puts ""
    puts "pbelasco 2009"
    puts "GPLv3"
    return false
  when (args[0].to_i.nil?)
    puts "Informe um código numérica válido"
    return false
  else 
    puts "ok, começando..."
    parsed_vars = []
    parsed_vars << args[0].to_i
    puts "buscando página de proposição de #{parsed_vars[0]}"
    parsed_vars
    
  end
end

def make_url(vars)
  url = "http://www.camara.gov.br/sileg/Prop_Detalhe.asp?id=#{vars[0]}"
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
  the_html = (doc/"/html/body/table//tr[2]/td/p").html
  unless doc.nil?
    # link que contem o id e o cod/ano da proposicao
    h = Hash.new("Este andamento")  
    h[:media_link] = (doc/"/html/body/table//tr[2]/td[2]/a").to_s.map { |s| s.split("HREF=\"")[1].split("\" ")[0] || nil } 
    h[:explicacao] = the_html.split(/[Explica][^o ]*o da Ementa: <\/b>/)[1].split("<b>")[0].strip || nil
    h[:apreciacao] = the_html.split(/[Aprecia][^o ]*o: <\/b>/)[1].split("<b>")[0].strip || nil
    h[:tramitacao] = the_html.split(/[Regime de tramita][^o ]*o: <\/b>/)[1].split("<b>")[0].strip || nil
    h[:despacho] = the_html.split(/[Despacho :]: <\/b>/)[1].split("<b>")[0].strip || nil 
    h[:id_sileg] = ARGV[0].to_i
    
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

# create_or_update_prop_batch(parse_elements(get_the_andamento_rows(get_parsed_page(make_url(parse_input(ARGV))))))
input = parse_input(ARGV) #453443 428043 164323
url = make_url(input)
parsed_page = get_parsed_page(url)

prop_desc = parse_prop_detalhes(parsed_page)
prop = create_or_update_prop(:id_sileg, prop_desc)

tags_desc = parse_tags(parsed_page)
create_or_update_tags(prop, tags_desc, :termo)

andamento_desc = get_the_andamento_rows(parsed_page)
andamentos = parse_andamentos(andamento_desc)
create_or_update_andamentos([:id_sileg, :data, :local, :descricao, :media_link], andamentos, prop)

# create_or_update_prop_batch(parsed_rows)
