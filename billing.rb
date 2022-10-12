require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "securerandom"
require_relative "format_duration"


configure do
  enable :sessions
  set :session_secret, 'secret'
  set :font_family, 'sans-serif'
  set :erb, :escape_html => true
end

helpers do
  def elapsed_time(timer)
    start_time = timer[:start_time]
    current_time = Time.now.to_time.to_i
    paused = timer[:paused_duration] + calculate_pause(timer)

    time = (start_time - current_time).abs - paused
    format_duration(time)
  end

  def total_time(timer)
    return false unless timer[:completed_time]
    
    start_time = timer[:start_time]
    completed_time = timer[:completed_time]
    paused = timer[:paused_duration]

    time = (start_time - completed_time).abs - paused
    format_duration(time)
  end

  def active_timers
    session[:timers].select do |timer|
      timer[:completed_time].nil?
    end
  end

  def completed_timers
    session[:timers].select do |timer|
      timer[:completed_time]
    end
  end
end

before do
  unless session[:timers] 
    session[:timers] = []
  end
end

def generate_id
  SecureRandom.uuid
end

def timer_from_id(id)
  session[:timers].find { |list| list[:id] == id }
end

def calculate_pause(timer)
  return 0 unless timer[:paused_time]
  current_time = Time.now.to_time.to_i
  (current_time - timer[:paused_time]).abs
end

def valid_input?(text)
  !text.empty?
end

get '/' do
  erb :index, layout: :layout
end

get '/new' do
  erb :new, layout: :layout
end

get '/timers/:id' do
  unless timer_from_id(params[:id])
    session[:error] = "Timer doesn't exist"
    redirect '/'
  end

  @timer = timer_from_id(params[:id])
  erb :timer, layout: :layout
end

post '/create_timer' do
  start_time = Time.now.to_time.to_i
  name = params[:name].strip
  description = params[:description]

  unless valid_input?(name) 
    session[:error] = "Name cannot be blank"
    redirect '/new'
  end
  timer = { id: generate_id, name: name, description: description, start_time: start_time, paused_duration: 0}

  session[:timers]  << timer
  redirect '/'
end

get '/timers/:id/edit' do
  @timer = timer_from_id(params[:id])
  erb :edit, layout: :layout
end

post '/timers/:id/edit' do
  @timer = timer_from_id(params[:id])
  @timer[:name] = params[:name].strip
  @timer[:description] = params[:description]

  redirect "/timers/#{@timer[:id]}"
end

post '/timers/:id/complete' do
  @timer = timer_from_id(params[:id])
  @timer[:paused_duration] += calculate_pause(@timer)
  @timer[:completed_time] = Time.now.to_time.to_i

  redirect '/'
end

post '/timers/:id/pause' do
  @timer = timer_from_id(params[:id])
  @timer[:paused_time] = Time.now.to_time.to_i

  redirect "/timers/#{@timer[:id]}"
end

post '/timers/:id/resume' do
  @timer = timer_from_id(params[:id])
  @timer[:paused_duration] += calculate_pause(@timer)
  @timer[:paused_time] = nil

  redirect "/timers/#{@timer[:id]}"
end