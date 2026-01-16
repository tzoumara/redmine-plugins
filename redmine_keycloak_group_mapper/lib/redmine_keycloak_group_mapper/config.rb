require 'yaml'

module RedmineKeycloakGroupMapper
  class Config
    def self.load
      @config ||= YAML.safe_load(
        File.read(
          Rails.root.join(
            'plugins',
            'redmine_keycloak_group_mapper',
            'config',
            'group_mapping.yml'
          )
        )
      )
    end
  end
end
