company = Company.find(4)
puts company.inspect
puts company.jobs.inspect
puts company.jobs.find(6).inspect
raise 'Unexpected jobs' unless company.jobs.count == 3
raise 'Unexpected company' unless company.jobs.find(6).name == 'Node'
puts 'Console associations: OK'
