ActiveRecord::Base.transaction do
  Apply.delete_all
  Job.delete_all
  Geek.delete_all
  Company.delete_all
  [Company, Job, Geek, Apply].each { |model| model.connection.reset_pk_sequence!(model.table_name) }

  companies = Company.create!([
    { name: 'MoGo', location: 'New York' },
    { name: 'Wirkkle', location: 'London' },
    { name: 'Artesis', location: 'Saint-Petersburg' },
    { name: 'BuildEmpire', location: 'London' }
  ])
  Job.create!([
    { name: 'Sinatra React', place: 'Remote', company: companies[0] },
    { name: 'Ruby React', place: 'Contract', company: companies[1] },
    { name: 'React', place: 'Remote', company: companies[2] },
    { name: 'Node React', place: 'Permanent', company: companies[0] },
    { name: 'Ruby on Rails', place: 'Remote', company: companies[3] },
    { name: 'Node', place: 'Permanent', company: companies[3] },
    { name: 'Javascript CSS HTML', place: 'Permanent', company: companies[3] }
  ])
  Geek.create!([
    { name: 'Mike', stack: 'Sinatra React', resume: 'Sinatra and React developer' },
    { name: 'Alex', stack: 'Ruby React', resume: 'Ruby and React developer' },
    { name: 'Martha', stack: 'Rails' },
    { name: 'Juri', stack: 'Java', resume: 'Java developer' },
    { name: 'Andrew', stack: 'PHP' },
    { name: 'Nina', stack: 'Node', resume: 'Node developer' },
    { name: 'Bob', stack: 'Front end', resume: 'Frontend developer' },
    { name: 'Kate', stack: 'PHP' },
    { name: 'Boris', stack: 'Full stack', resume: 'Full stack developer' }
  ])
  Apply.create!([
    { job_id: 1, geek_id: 1, read: true, invited: true },
    { job_id: 1, geek_id: 2, read: false, invited: false },
    { job_id: 5, geek_id: 5, read: true, invited: false },
    { job_id: 6, geek_id: 8, read: false, invited: false }
  ])
end
