require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"


configure do
  enable :sessions
  set :session_secret, 'secret'
  set :font_family, 'sans-serif'
  set :erb, :escape_html => true
end

before do
  unless @active_timers
    @active_timers = []
  end
  unless @completed_timers
    @completed_timers = []
  end
end

get '/' do
  erb :index, layout: :layout
end

get '/new' do
  erb :new, layout: :layout
end

post '/create_timer' do
  
end