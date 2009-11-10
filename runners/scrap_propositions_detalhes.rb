#!/usr/bin/ruby
require 'rubygems'
require 'hpricot'
require 'curb'
require "iconv"

# recebe Input e retorna parsed_vars ou false em caso de erro
def parse_input(args)
  # /(\()([A-Za-z][A-Za-z0-9+.-]+:[A-Za-z0-9/](([A-Za-z0-9$_.+!*,;/?:@&~=-])|%[A-Fa-f0-9]{2})+(#([a-zA-Z0-9][a-zA-Z0-9$_.+!*,;/?:@&~=%-]*))?)/

  parsed_vars = []
  if args[0].to_s.include?('id=')
    puts "ok, começando por id..."
    parsed_vars << args[0].split("=")[1]
  elsif args[0].to_s.include?('range=')
    puts "ok, começando por range..."
    range = args[0].split("=")[1]
    parsed_vars = Proposicao.find(:all, :limit => range).map {|p| p.id_sileg } 
  else    
    puts "Modo de uso 'scrap_propositions_detalhes.rb <id=<id_sileg>'"
    puts "Exemplo:"
    puts "Carrega as informacoes da proposicao: "
    puts "$script/runner scrap_propositions_detalhes.rb id=21424124"
    puts "$script/runner scrap_propositions_detalhes.rb range='0,10'"
    puts "pbelasco 2009"
    puts "GPLv3"
    nil
  end
  parsed_vars || nil
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

  # doc = Hpricot.parse( enc.iconv(c.body_str), :fixup_tags => true )
  doc = Hpricot.parse( enc.iconv(c.body_str) )
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
      puts "aguardando 20 segundos para tentar novamente..."
      sleep 20
      c = perform_req(curl_obj)
    else 
      return c # Condição de parada na pilha
    end
  rescue Exception => e
    puts e.inspect
    puts "erro no servidor, devolvendo nulo"
    puts "aguardando 20 segundos para tentar novamente..."
    sleep 20
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
end

def parse_prop_detalhes(doc)
  puts "começando parsing dos andamentos..."
  prop_detalhes = []
  h = Hash.new("Este andamento")  
  unless doc.nil?
    # h[:autor] = doc.at('tr/td[2]//tbody').inner_text.split(/:/)[1].strip || nil
    # h[:autor] = doc.at('table/tbody/tr[2]/td[2]/table/tbody/tr/td[2]/a') || nil
    h[:autor_link] = nil

    h[:media_link] = (doc/"/html/body/table//tr[2]/td[2]/a").to_s.map { |s| s.split("HREF=\"")[1].split("\" ")[0] || nil } 

    unless (doc/"/html/body/table//tr[2]/td//").html == ""

      str = (doc/"/html/body/table//tr[2]/td//").html || ""

      spl = str.split(/[Explica][^o ]*o da Ementa: <\/b>/)[1]
      unless spl.nil?
        h[:explicacao] =  spl.split("<b>")[0].strip || nil
      end
      if spl = str.split(/[Aprecia][^o ]*o: <\/b>/)[1]
        h[:apreciacao] =  spl.split("<b>")[0].strip || nil
      end
      if spl = str.split(/[Regime de tramita][^o ]*o: <\/b>/)[1].split
        h[:tramitacao] =  str.split("<b>")[0].strip || nil
      end
      if spl = str.split(/[Despacho :]: <\/b>/)[1]
        h[:despacho]   =  spl.split("<b>")[0].strip || nil 
      end
      if spl = str.split(/[Acess][^r]*[ria de: <\/b>]/)[1]
        h[:acessoria_de] = spl.split("<b>")[0].strip || nil 
      end
    end
    puts "#{h.inspect}\nDetalhes de Proposta ----------------------------------------" unless h.empty?
    h
  end
end
def parse_and_create_andamentos(proposta, rows)
  puts "começando parsing dos andamentos..."
  andamentos = []

  rows.each do |row| 
    unless row.empty? 
      # link que contem o id e o cod/ano da proposicao
      h = Hash.new("Este andamento")  
      h[:local] = (row/"b").first.inner_html.to_s.strip.split("&nbsp;").join(" ").gsub(/(\r\n)|\t/, "") || nil
      h[:descricao] = (row/"td")[1].html.split("<br />")[1].strip || nil
      h[:data] = (row/"td")[0].inner_html.strip.split("/").reverse.join("-") || nil
      h[:media_link] = (row/'a[@HREF]').to_s.map { |s| s.split("HREF=\"")[1].split("\" ")[0] || nil }
      h[:id_sileg] = @parsed_vars[0]

      puts "#{h.inspect}\nAndamento --------------------------------------------------" unless row.empty?
      andamentos << h
    end 
  end   
  create_or_update_andamentos(:id_sileg, andamentos, proposta)

  puts "criados/atualizados #{andamentos.size} registros"
  andamentos
end

def inspect_detalhes(h)
  h.inspect
end

def create_or_update_prop(id_sileg, h)
  p = Proposicao.find_by_id_sileg(id_sileg)
  if p
    p.update_attributes(h) 
  else
    p = Proposicao.create(h)
  end
  p
end

def create_or_update_andamentos(fields, novos_andamentos, proposta)
  proposta.andamentos.each {|a| a.destroy} unless proposta.andamentos.empty?
  novos_andamentos.each do |h|
    a = Andamento.create(h)
    proposta.andamentos << a
  end
end

def create_or_update_tags(proposta, tags_str)
  puts "Tags ---------------------------------------------------"
  tags_str.split(",").each do |t|
    unless t.strip.match("^[_].*|[<br />]") 
      tag = Tag.find_by_termo(t)
      if tag
        Tag.update(tag.id, { :termo => t })
      else 
        Tag.create({ :termo => t })
      end
      proposta.tags << tag unless proposta.tags.empty? || proposta.tags.find(tag)
    end
    puts tag.inspect
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
@parsed_vars = parsed_input
unless parsed_input.nil? 
  parsed_input.each do |id|
    url = make_url(id)
    parsed_page = get_parsed_page(url)
    proposta = create_or_update_prop(id, parse_prop_detalhes(parsed_page))
    create_or_update_tags(proposta, parse_tags(parsed_page))
    andamentos = parse_and_create_andamentos(proposta, get_the_andamento_rows(parsed_page))
  end  
end