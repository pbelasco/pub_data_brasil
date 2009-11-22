class UpdateCamaraProposition < Struct.new(:id_sileg)
  require 'rubygems'
  require 'hpricot'
  require 'curb'
  require "iconv"
  
  def perform
    puts "Atualizando proposicao #{id_sileg} da Camara Federal"
    url = make_url(id_sileg)
    puts "mkurl: #{url}"
    parsed_page = get_parsed_page(url)
    puts "parsing: #{parsed_page}" 
    proposta = create_or_update_prop(id, parse_prop_detalhes(parsed_page))
    puts "proposta: #{proposta}" 
    tags = create_or_update_tags(proposta, parse_tags(parsed_page))
    puts "tags: #{tags}"
    andamentos = parse_and_create_andamentos(proposta, get_the_andamento_rows(parsed_page))
    puts "andamentos: #{andamentos}"
    
    true
  end

  def make_url(var)
    url = "http://www.camara.gov.br/sileg/Prop_Detalhe.asp?id=#{var}"
    puts url.to_s
    url
  end

  # recebe url e devolve hpricot parsed doc string
  # recebe url e devolve hpricot parsed doc string
  def get_parsed_page(url)

    c = Curl::Easy.new("#{url}") do |curl|
      curl.headers["User-Agent"] = "Legisdados v.001"
      curl.verbose = true
    end
    puts "tentando obter resultado de #{url}"
    # c = perform_req(c)
    c.perform
    enc = Iconv.new('UTF-8', 'ISO-8859-1')

    # doc = Hpricot.parse( enc.iconv(c.body_str), :fixup_tags => true )
    doc = Hpricot.parse( enc.iconv(c.body_str) )
    # puts doc.html
    puts "obtido!"
    doc
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
    puts "parsenado tags"
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
          h[:acessoria_de] = spl.to_s.split("<b>")[0] || nil 
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
        h[:descricao] = (row/"td")[1].html.to_s.split("<br />")[1].strip || nil
        h[:data] = (row/"td")[0].inner_html.to_s.strip.split("/").reverse.join("-") || nil
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
      puts "proposicao atualizada"
    else
      p = Proposicao.create(h)
      puts "proposicao criada"
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
  end

end