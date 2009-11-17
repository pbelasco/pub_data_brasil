#!/usr/bin/ruby
require 'rubygems'
require 'hpricot'
require 'curb'
require "iconv"

# recebe Input e retorna parsed_vars ou false em caso de erro
def parse_input(args)
  case args
  when args.size < 2 
    puts "Modo de uso 'scrap_propositions.rb < ano > < pagina_inicial[->pagina_final] >'"
    puts "Exemplo"
    puts "Carrega as props de 1990 das páginas 1 a 15: "
    puts "$script/runner scrap_propositions.rb '1990' '1->15'"
    puts ""
    puts "pbelasco 2009"
    puts "GPLv3"
    return false
  when (1947..Date.today.year.to_i).member?(args[0].to_i)
    puts "Informe um ano com 4 digitos maior que 1946 e menor que o ano corrente"
    return false
  else 
    puts "ok, começando..."
    parsed_vars = []
    parsed_vars << args[0].to_i
    parsed_vars << args[1].split("->")[0].to_i
    parsed_vars << args[1].split("->")[1].to_i == nil? ? parsed_vars[1] : args[1].split("->")[1].to_i
    puts "buscando páginas de proposições de #{parsed_vars[1]} a #{parsed_vars[2]} no ano #{parsed_vars[0]}"
    parsed_vars
  end
end

def make_urls(vars)
  ano = vars[0]
  pag_inicial = vars[1]
  pag_final = vars[2] || vars[1]
  urls = []
  (pag_inicial..pag_final).each do |p| 
    urls << "http://www.camara.gov.br/sileg/Prop_Lista.asp?Pagina=#{p}&Numero=&Ano=#{ano}&OrgaoOrigem=todos"
  end
  urls
end

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
  end
end

def get_the_rows(doc)
  # Tabela que contem os elementos
  # Colunas de 1 a 32... é isso mesmo... é a única maneira que consegui para extrair estas coisas
  rows  = [] 
  puts "selecionando elementos..."
  (3..50).each do |i| 
    # cada uma das tabelas que contém a descrição das proposicaos
    # usando XPath para encontrar os elementos no nível desejado
    e   = (doc/"//table//td[2]//table//tr[#{i.to_i}]//table")
    unless e.nil?
      rows << e 
    end
  end
  puts "encontrei #{rows.size}"
  rows
end

def parse_elements_and_create(rows)
  puts "começando parsing..."
  props = []
  rows.each do |row| 
    unless row.empty? 
      # link que contem o id e o cod/ano da proposicao
      h = Hash.new("Esta Proposicao")  
      h[:link]         = (row/"a[@href]").first.get_attribute("href").to_s.strip || nil
      h[:id_sileg]     = (row/"a[@href]").first.get_attribute("href").split("=").last.to_s.strip || nil
      h[:descricao]    = (row/"a[@href]").first.inner_html.split('<img')[0].strip || nil   
      h[:orgao]        = (row/"tr/td[2]").first.inner_html.strip || nil    
      h[:autor]        = (row/"tr/td[2]").last.inner_html.strip || nil
      h[:apresentacao] = (row/"tr[3]/td/[2]").first.to_s.strip.split("/").reverse.join("-") || nil
      h[:ementa]       = (row/"tr[3]/td/[3]").first.to_s.strip || nil
      h[:despacho]     = (row/"tr[4]/td/[2]").last.to_s.strip || nil
      h[:situacao]     = (row/'/tr/td[3]').inner_html || nil

      puts "#{h.inspect}\n-------------------------------÷---------------------------------------------" unless row.empty?
      props << h
      
      if nova_proposicao = Proposicao.find_by_id_sileg(h[:id_sileg]) 
        nova_proposicao.update_attributes(h)
      else 
        nova_proposicao = Proposicao.create(h)
      end
      nova_proposicao
    end 
  end 
  puts "criados/atualizados #{props.size} registros"
end

make_urls(parse_input(ARGV)).each do |url|
  parse_elements_and_create(get_the_rows(get_parsed_page(url)))
end