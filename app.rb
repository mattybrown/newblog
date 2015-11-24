require 'bundler'
Bundler.require

require './model'
require './strategy'

class NewsBlog < Sinatra::Base

  enable :sessions
  register Sinatra::Flash
  set :session_secret, "secret"

  use Warden::Manager do |config|
    config.serialize_into_session{ |user| user.id }
    config.serialize_from_session{ |id| User.get(id) }

    config.scope_defaults :default, strategies: [:password], action: 'auth/unauthenticated'
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env, opts|
    env['REQUEST_METHOD'] = 'POST'
  end


  get '/' do
    @stories = Story.all
    erb :index
  end

  get '/read/:id' do
    @story = Story.get(params[:id])
    erb :story
  end

  get '/admin' do
    env['warden'].authenticate!
    @stories = Story.all
    erb :admin
  end

  get '/story/create' do
    env['warden'].authenticate!
    erb :create_story
  end

  post '/story/create' do
    env['warden'].authenticate!
    story = Story.new(:title => params["story"]["title"],:body => params["story"]["body"], :file => params["story"]["image"], :summary => params["story"]["summary"])
    if story.nil?
      flash[:error] = "Something went wrong!"
      redirect '/admin'
    else
      flash[:success] = "Story created"

      story.save
      redirect '/admin'
    end
  end

  get '/story/delete/:id' do
    env['warden'].authenticate!
    story = Story.get(params[:id])
    if story
      story.destroy
      flash[:success] = "Story deleted"
      redirect '/admin'
    else
      flash[:error] = "Something went wrong"
      redirect '/admin'
    end
  end

  get '/story/edit/:id' do
    env['warden'].authenticate!
    story = Story.get(params[:id])
    if story
      @story = story
      erb :edit_story
    else
      flash[:error] = "Whoops, couldn't find that story!"
      redirect '/admin'
    end
  end

  post '/story/update/:id' do
    env['warden'].authenticate!
    story = Story.get(params[:id])
    story.update(:title => params["story"]["title"],:body => params["story"]["body"], :file => params["story"]["image"], :summary => params["story"]["summary"])
    if story.nil?
      flash[:error] = "Something went wrong!"
      redirect '/admin'
    else
      flash[:success] = "Story updated"

      story.save
      redirect '/admin'
    end
  end


#user login logic
#
#

  get '/auth/login' do
    erb :login
  end

  post '/auth/login' do
    env['warden'].authenticate!
    flash[:success] = env['warden'].message

    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end

  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    flash[:success] = 'Successfully logged out'
    redirect '/'
  end

  post '/auth/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?
    flash[:error] = env['warden.options'][:message] || "You must log in to do that"
    redirect '/auth/login'
  end



end
