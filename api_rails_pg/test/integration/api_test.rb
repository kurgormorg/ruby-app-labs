require 'test_helper'

class ApiTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: 'Test company', location: 'Moscow')
    @job = @company.jobs.create!(name: 'Ruby', place: 'Remote')
    @geek = Geek.create!(name: 'Test geek', stack: 'Ruby')
    @apply = Apply.create!(job: @job, geek: @geek)
  end

  test 'nested jobs are scoped to their company and serialized' do
    get "/v1/companies/#{@company.id}/jobs"
    assert_response :ok
    assert_equal [{ 'name' => 'Ruby', 'place' => 'Remote', 'company_id' => @company.id }], response.parsed_body['jobs']
    other = Company.create!(name: 'Other', location: 'London')
    get "/v1/companies/#{other.id}/jobs/#{@job.id}"
    assert_response :not_found
  end

  test 'crud for all four resources' do
    [
      ['companies', { name: 'New', location: 'London' }, { location: 'Minsk' }],
      ['jobs', { name: 'JS', place: 'Remote', company_id: @company.id }, { place: 'Minsk' }],
      ['geeks', { name: 'New', stack: 'JS' }, { stack: 'Ruby' }],
      ['applies', { job_id: @job.id, geek_id: @geek.id }, { read: true }]
    ].each do |resource, attributes, changes|
      post "/v1/#{resource}", params: attributes, as: :json
      assert_response :created
      id = response.parsed_body['id']
      get "/v1/#{resource}/#{id}"
      assert_response :ok
      put "/v1/#{resource}/#{id}", params: changes, as: :json
      assert_response :ok
      delete "/v1/#{resource}/#{id}"
      assert_response :ok
      assert Job.find(id).deleted if resource == 'jobs'
    end
  end

  test 'validation and missing routes return json errors' do
    post '/v1/jobs', params: { name: '.NET', place: 'Minsk' }, as: :json
    assert_response 422
    assert response.parsed_body['errors'].key?('company_id')
    put "/v1/applies/#{@apply.id}", params: { invited: nil }, as: :json
    assert_response 422
    get '/v1/jobs/0'
    assert_response :not_found
    assert_equal 'not_found', response.parsed_body['status']
    get '/jobs'
    assert_response :not_found
    assert_equal 'no_route', response.parsed_body['status']
  end

  test 'application actions and relations' do
    put "/v1/applies/#{@apply.id}/mark_read"
    assert_response :ok
    assert @apply.reload.read
    put "/v1/applies/#{@apply.id}/invite"
    assert_response :ok
    assert @apply.reload.invited
    ["/v1/jobs/#{@job.id}/geeks", "/v1/jobs/#{@job.id}/invited_geeks",
     "/v1/geeks/#{@geek.id}/jobs", "/v1/geeks/#{@geek.id}/invited_jobs",
     "/v1/geeks/#{@geek.id}/companies", "/v1/companies/#{@company.id}/applies",
     "/v1/jobs/#{@job.id}/applies", "/v1/geeks/#{@geek.id}/applies",
     '/v1/applies?read=true&invited=true'].each do |path|
      get path
      assert_response :ok
      assert_equal 1, response.parsed_body.values.first.size
    end
    put "/v1/geeks/#{@geek.id}/resume", params: { resume: 'Ruby developer' }, as: :json
    assert_response :ok
    assert_equal 'Ruby developer', @geek.reload.resume
  end

  test 'filters and logical deletion' do
    get '/v1/companies', params: { name: @company.name, location: @company.location }
    assert_equal [@company.id], response.parsed_body['companies'].map { |company| company['id'] }
    get '/v1/jobs', params: { name: @job.name, place: @job.place }
    assert_equal 1, response.parsed_body['jobs'].size
    get '/v1/geeks', params: { name: @geek.name, stack: @geek.stack }
    assert_equal [@geek.id], response.parsed_body['geeks'].map { |geek| geek['id'] }
    put "/v1/companies/#{@company.id}/mark_deleted"
    assert_response :ok
    assert @company.reload.deleted
    assert Job.exists?(@job.id)
    put "/v1/companies/#{@company.id}/mark_deleted"
    assert_equal 'not_modified', response.parsed_body['deleted_already']
  end
end
