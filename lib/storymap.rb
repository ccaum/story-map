require 'jira'

class StoryMap
  class AuthenticationRedirect < Exception; end
  class ClientUnauthorized < Exception; end

  attr_accessor :authenticate_url, :client, :session

  def initialize(options)
    @client = JIRA::Client.new(options)
  end

  def connected?
    if authenticated?
      @client.set_access_token(
        session[:jira_auth][:access_token],
        session[:jira_auth][:access_key]
      )
    end
    authenticated?
  end

  def callback(oauth_verifier)
    request_token = @client.set_request_token(
      session[:jira_auth][:request_token], session[:jira_auth][:request_secret]
    )
    access_token = @client.init_access_token(
      :oauth_verifier => oauth_verifier
    )

    session[:jira_auth] = {
      :access_token => access_token.token,
      :access_key => access_token.secret
    }

    session[:jira_auth].delete(:request_token)
    session[:jira_auth].delete(:request_secret)
  end

  def connect
    authenticate
  end

  def authenticated?
    session[:jira_auth][:access_key] and session[:jira_auth][:access_token]
  end

  def authenticate
    begin
      request_token = @client.request_token
    rescue OAuth::Unauthorized
      raise ClientUnauthorized, 'Make sure you\'ve linked this application to Jira'
    end

    session[:jira_auth][:request_token]  = request_token.token
    session[:jira_auth][:request_secret] = request_token.secret

    @authenticate_url = request_token.authorize_url

    raise AuthenticationRedirect
  end


  def disconnect
    session.delete :jira_auth
  end

  def features
    features = Array.new

    @client.Issue.jql('type = Epic').each do |feature|
      children = feature.issuelinks.find_all { |link| link.type.outward == 'parent of' }.collect do |child|
        @client.Issue.find(child.outwardIssue.key)
      end

      features << {:feature => feature, :children => children}
    end

    features
  end

  def update_relationship(relationships)
    relationships.each do |epic,stories|
      epic = @client.Issue.find(epic)

      children = epic.issuelinks.find_all { |link| link.type.outward == 'parent of' }.collect do |child|
        child.outwardIssue.key
      end

      stories.each do |story_id|
        unless children.include? story_id

          #Find the old relationship and delete it
          old_relationship = @client.Issuelink.all.find do |link|
            link.type.name == 'child relationships' and link.outwardIssue.key == story_id
          end

          @client.delete(client.options[:rest_base_path] + "/issueLink/#{old_relationship.id}")

          #Set the new relationship
          parameters = {
            'inwardIssue' =>  {
              'key' => epic.key
            },
            'outwardIssue' => {
              'key' => story_id
            },
            'type' => {
              'name' => 'child relationships'
            }
          }.to_json

          @client.post(client.options[:rest_base_path] + "/issueLink", parameters)
        end
      end
    end
  end
end
