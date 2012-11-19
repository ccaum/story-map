require 'sinatra'
require 'jira'
require 'yaml'
require 'lib/storymap'

class StoryMapApp < Sinatra::Base

  helpers do
    def client
      settings.client
    end
  end

  configure do
    options = YAML::load(IO.read('config.yaml'))
    set :client, StoryMap.new(options)
  end

  before do
    session[:jira_auth] ||= Hash.new
    client.session = session

    begin
      unless env['PATH_INFO'] == '/callback/'
        client.connect unless client.connected?
      end
    rescue StoryMap::AuthenticationRedirect
      redirect client.authenticate_url
    end
  end

  get '/' do
    erb :index
  end

  get "/callback/" do
    client.callback params[:oauth_verifier]

    redirect "/"
  end

  get "/signout" do
    settings.client.disconnect

    redirect "/"
  end

  post '/relationship' do
    client.update_relationship params
  end
end
