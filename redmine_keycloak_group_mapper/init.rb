Redmine::Plugin.register :redmine_keycloak_group_mapper do
  name 'Redmine Keycloak Group Mapper'
  author 'Thierry Zoumara'
  description 'Maps Keycloak groups/roles to Redmine groups and project roles (strict sync supported)'
  version '1.0.0'
  requires_redmine version_or_higher: '6.1.0'
end

require_relative 'lib/redmine_keycloak_group_mapper/hooks'
