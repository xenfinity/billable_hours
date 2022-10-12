ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "billing"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup

  end

  def create_test_timer(name, description)
    start_time = Time.now.to_time.to_i
    { id: generate_id, name: name, description: description, start_time: start_time, paused_duration: 0}
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
  end

  def test_add_timer
    get '/new'
    assert_equal 200, last_response.status

    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "timer_name"
  end

  def test_add_timer_empty_name
    get '/new'
    assert_equal 200, last_response.status

    post '/create_timer', { name: "", description: "description" }
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Name cannot be blank"
  end

  def test_view_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    id = session[:timers].first[:id]
    get "/timers/#{id}"
    assert_equal 200, last_response.status
  end

  def test_view_nonexistent_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    id = "nonexistent_id"
    get "/timers/#{id}"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Timer doesn't exist"
  end

  def test_edit_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    id = session[:timers].first[:id]
    get "/timers/#{id}/edit"
    assert_equal 200, last_response.status

    post "/timers/#{id}/edit", { name: "new_name", description: "new_description"}
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new_name"

    get "/timers/#{id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new_description"
  end

  def test_complete_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    id = session[:timers].first[:id]
    post "/timers/#{id}/complete"
    assert_equal 302, last_response.status

    assert !session[:timers].first[:completed_time].nil?
    
  end

  def test_pause_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status

    id = session[:timers].first[:id]
    post "/timers/#{id}/pause"
    assert_equal 302, last_response.status

    assert !session[:timers].first[:paused_time].nil?
    
  end

  def test_resume_timer
    post '/create_timer', { name: "timer_name", description: "description" }
    assert_equal 302, last_response.status


    id = session[:timers].first[:id]
    post "/timers/#{id}/pause"
    assert_equal 302, last_response.status

    post "/timers/#{id}/resume"
    assert_equal 302, last_response.status

    assert session[:timers].first[:paused_time].nil?
    
  end



end