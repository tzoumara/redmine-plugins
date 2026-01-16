require_relative 'mapper'

module RedmineKeycloakGroupMapper
  class Hooks < Redmine::Hook::Listener
    def controller_account_success_authentication_after(context = {})
      user = context[:user]
      request = context[:request]
      return unless request&.env
      oauth_data = request.env['omniauth.auth']
      return unless oauth_data
      Mapper.apply(user, oauth_data)
    rescue => e
      Rails.logger.error("[KeycloakGroupMapper] #{e.message}")
    end
  end
end
