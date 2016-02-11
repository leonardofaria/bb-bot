gem 'mechanize', '2.7.2'
require 'mechanize'
require 'time_difference'
require 'pony'
require 'mail'
require 'terminal-table'

def sendmail(to, subject, body)
	Pony.mail({
	  :to => to,
	  :via => :smtp,
	  :subject => subject,
	  :body => body,
	  :from => to,
	  :html_body => body,
	  :charset => 'UTF-8',
		:text_part_charset => 'UTF-8',
	  :via_options => {
			:address => 'smtp.gmail.com',
			:port => '587',
			:domain => 'heroku.com',
			:user_name => ENV['BB_USERNAME'],
			:password => ENV['BB_PASSWORD'],
			:authentication => :plain,
			:enable_starttls_auto => true
	  }
	})
end

url = 'http://www37.bb.com.br/portalbb/tabelaRentabilidade/rentabilidade/gfi7,802,9085,9089,9.bbx?tipo=2&nivel=1000'
mechanize = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }
page = mechanize.get(url)

body = Nokogiri::HTML(page.body)
rows = body.xpath("//table[contains(concat(' ', @class, ' '), ' tb_accordion ')]")[1].css("tbody tr")

investiments = [rows[1], rows[2], rows[3], rows[5], rows[7], rows[9], rows[10], rows[11]]
investiments_table = []

investiments.each do |investiment|
	investiments_table << [
		investiment.css('td')[0].text.strip.gsub("BB ", ""), # nome
		investiment.css('td')[1].text.strip, # dia
		investiment.css('td')[2].text.strip, # mes
		investiment.css('td')[3].text.strip, # mes anterior
		investiment.css('td')[4].text.strip, # ano
		investiment.css('td')[5].text.strip, # 12 meses
		investiment.css('td')[6].text.strip, # 24 meses
		investiment.css('td')[7].text.strip  # 36 meses
	]
end

content = Terminal::Table.new(
	headings: ['Nome', 'Dia', 'Mês', 'Anterior', '2016', '1 ano', '2 anos', '3 anos'],
	rows: investiments_table
)

puts content

output = "<div style='display: none; white-space: nowrap; line-height: 0; color: #ffffff;'>+----------------------+-------+--------+--------------+--------+----------+----------+----------+</div><pre>#{content}</pre>"
sendmail(ENV['BB_EMAIL'], 'BB - Fundos de investimento', output)
