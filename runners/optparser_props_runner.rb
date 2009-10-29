# == Descrição
# Le arquivo e separa linha por linha em formato de legenda.
# Recebe Nome do Arquivo, duração do Filme em minutos, nome de saída
#
# == Exemplos
#   txt2srt converte um arquivo txt plano para uma versão srt com -l <minutos> de duracao
#     txt2srt -i foo.txt -l time.minutes > bar.txt
#
# == Uso
#   txt2srt [-i] <file.ext> -l <minutes> > out.srt
#
#   Para ajuda, use -h: txt2srt -h
#
# == Opções
#   -i --input <file.ext> Processa o arquivo
#   -h, --help            Mostra esta ajuda
#   -v, --version         Mostra detalhe da versão
#
# == Autor
#   Pedro Belasco <pbelasco@gmail.com>
#   estudio cromatica ltd.
#
# == Copyright
#   Copyright (c) 2009 pbelasco@gmail.com. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php

require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
require 'rubygems'
require 'hpricot'
require 'curb'
require "iconv"

class App
  VERSION = '0.0.1'
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.ids = []
    @options.range = "0,0"
    @options.quiet = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      puts "Início em #{DateTime.now}\n\n" if @options.verbose
      output_options if @options.verbose # [Optional]
      process_arguments            
      process_command
      puts "\nTérmino em #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-i id', '--id id', String) do |id|
        @options.ids << id
      end
      opts.on('-r range', '--range range', String) do |range|    
        @options.range = range.to_s
      end
      opts.on('-q', '--quiet') { 
        output_version ; exit 0 
      }   
      opts.on('-v', '--version') { 
        output_version ; exit 0 
      }
      opts.on('-h', '--help') { 
        output_help; exit 0
      }
      
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Opções:\n"
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      # TO DO - implement your real logic here
      # if File.exists?(@options.infile) && File.readable?(@options.infile) 
        return true
      # else
        # puts "Arquivo ilegível ou inexistente. Encerrando"
      # end
    end
    
    # Setup the arguments
    def process_arguments
      unless @options.range.empty?
        Proposicao.find(:all, :limit => @options.range).each do |prop| 
          @options.ids << prop.id_sileg 
        end
      end
      # TO DO - place in local vars, etc
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      @options.ids.each do |id|
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
      #process_standard_input # [Optional]
    end

    def process_standard_input
      # input = @stdin.read      
      # TO DO - process input
      
      # [Optional]
      # @stdin.each do |line| 
      #  # TO DO - process each line
      #end
    end
end


# TO DO - Add your Modules, Classes, etc

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
  unless doc.nil? || the_html.nil?
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


# Create and run the application
app = App.new(ARGV, STDIN)
app.run