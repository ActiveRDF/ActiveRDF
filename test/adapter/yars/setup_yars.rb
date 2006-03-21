def setup_yars context
	dirname = File.dirname(__FILE__)
	`java -jar #{dirname}/yars-api-current.jar -d -u http://#{DB_HOST}:8080/#{context} #{dirname}/delete_all.nt`
	`java -jar #{dirname}/yars-api-current.jar -p -u http://#{DB_HOST}:8080/#{context} #{dirname}/../../test_set_person.nt`
end

def delete_yars context
	dirname = File.dirname(__FILE__)
	`java -jar #{dirname}/yars-api-current.jar -d -u http://#{DB_HOST}:8080/#{context} #{dirname}/delete_all.nt`
end
