require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "securerandom"


require_relative "time_calculation"
require_relative "session_persistence"
require_relative "database_persistence"

DATABASE = true

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :font_family, 'sans-serif'
  set :erb, :escape_html => true
end

def initiate_persistence(session, logger)
  @storage = if DATABASE
               DatabasePersistence.new(logger)
             else
               SessionPersistence.new(session)
             end
end

def close_database_connection
  @storage.close_connection
end

helpers do
  
  def active_timers
    @storage.timers.select do |timer|
      timer[:completed_time].nil?
    end
  end

  def completed_timers
    p "timers #{@storage.timers}"
    @storage.timers.select do |timer|
      timer[:completed_time]
    end
  end

  def elapsed_time(timer_id)
    timer = @storage.timer_from_id(timer_id)
    elapsed_time = calculate_elapsed(timer)
    format_duration(elapsed_time)
  end

  def completed_time(timer_id)
    return false unless @storage.timer_from_id(timer_id)[:completed_time]
    timer = @storage.timer_from_id(timer_id)
    completed_time = calculate_completed(timer)
    format_duration(completed_time)
  end

end

def valid_input?(text)
  !text.empty?
end

before do
  initiate_persistence(session, logger)
end

after do
  close_database_connection if DATABASE
end

get '/' do
  erb :index, layout: :layout
end

get '/new' do
  erb :new, layout: :layout
end

get '/timers/:id' do
  unless @storage.timer_from_id(params[:id])
    session[:error] = "Timer doesn't exist"
    redirect '/'
  end

  @timer = @storage.timer_from_id(params[:id])
  erb :timer, layout: :layout
end

post '/create_timer' do
  name = params[:name].strip
  description = params[:description]
  start_time = Time.now.to_time.to_i

  unless valid_input?(name) 
    session[:error] = "Name cannot be blank"
    redirect '/new'
  end
  @storage.create_timer(name, description, start_time)
  redirect '/'
end

get '/timers/:id/edit' do
  @timer = @storage.timer_from_id(params[:id])
  erb :edit, layout: :layout
end

post '/timers/:id/edit' do
  timer_id = params[:id]
  name = params[:name].strip
  description = params[:description].strip
  @storage.edit_timer(timer_id, name, description)
  
  redirect "/timers/#{timer_id}"
end

post '/timers/:id/complete' do
  timer_id = params[:id]
  completed_time = Time.now.to_time.to_i
  @storage.complete_timer(timer_id, completed_time)

  redirect '/'
end

post '/timers/:id/pause' do
  timer_id = params[:id]
  paused_time = Time.now.to_time.to_i
  @storage.pause_timer(timer_id, paused_time)
  
  redirect "/timers/#{timer_id}"
end

post '/timers/:id/resume' do
  timer_id = params[:id]
  @storage.resume_timer(timer_id)

  redirect "/timers/#{timer_id}"
end
  
