Proposicao.find(:all).each do |p| 
 if p.descricao and p.descricao.match '=> ' 
  puts "encontrei #{p.descricao}"
  apensada = /([A-Z]{1,7}-[0-9]{1,6}\/[0-9]{4})/.match(p.descricao.split('=>').last.strip).to_s 
  puts "fazendo referencia a #{apensada}"
  if atal = Proposicao.find_by_descricao(apensada.to_s)
   puts "a tal foi encontrada... #{atal.descricao}, id_sileg => #{atal.id_sileg}" 
   Apensa.create(:original => p.id, :apensada => Proposicao.find_by_descricao(apensada.to_s).id)
  else
   puts "não pude encontrar com certeza a proposicao correta. Procurei por #{apensada}"
  end
 end
end