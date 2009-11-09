Given /^I have paginas called (.+)$/ do |titulos|
  titulos.split(", ").each { |titulo| Pagina.create(:titulo => titulo) }
end
