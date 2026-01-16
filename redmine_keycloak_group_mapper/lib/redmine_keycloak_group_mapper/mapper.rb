require_relative 'config'
require 'set'

module RedmineKeycloakGroupMapper
  class Mapper
    def self.apply(user, oauth_data)
      config = Config.load
      claim = config.dig('keycloak', 'claim')
      sync_mode = config.dig('sync', 'mode') || 'additive'
      raw_info = oauth_data.dig('extra', 'raw_info') || {}
      kc_values = Array(raw_info[claim])
      desired = build_desired_state(config['mappings'], kc_values)
      apply_admin(user, desired[:admin])
      sync_groups(user, desired[:groups], sync_mode)
      sync_projects(user, desired[:projects], sync_mode)
    end

    def self.build_desired_state(mappings, kc_values)
      state = { admin: false, groups: Set.new, projects: {} }
      mappings.each do |kc_group, rules|
        next unless kc_values.include?(kc_group)
        state[:admin] ||= rules['admin'] == true
        state[:groups] << rules['redmine_group'] if rules['redmine_group']
        next unless rules['projects']
        rules['projects'].each do |pid, pdata|
          state[:projects][pid] ||= Set.new
          pdata['roles'].each { |r| state[:projects][pid] << r }
        end
      end
      state
    end

    def self.apply_admin(user, admin_required)
      return if user.admin? == admin_required
      user.update!(admin: admin_required)
    end

    def self.sync_groups(user, desired, mode)
      managed = managed_groups
      desired.each do |name|
        g = Group.find_or_create_by!(name: name)
        g.users << user unless g.users.include?(user)
      end
      return unless mode == 'strict'
      user.groups.each do |g|
        next unless managed.include?(g.name)
        next if desired.include?(g.name)
        g.users.delete(user)
      end
    end

    def self.sync_projects(user, desired, mode)
      managed = managed_project_roles
      desired.each do |pid, roles|
        project = Project.find_by(identifier: pid)
        next unless project
        member = Member.find_or_initialize_by(user: user, project: project)
        member.save! unless member.persisted?
        roles.each do |rname|
          role = Role.find_by(name: rname)
          next unless role
          member.roles << role unless member.roles.include?(role)
        end
      end
      return unless mode == 'strict'
      user.members.each do |member|
        pid = member.project.identifier
        next unless managed.key?(pid)
        desired_roles = desired[pid] || Set.new
        member.roles.each do |role|
          next unless managed[pid].include?(role.name)
          next if desired_roles.include?(role.name)
          member.roles.delete(role)
        end
        member.destroy if member.roles.empty?
      end
    end

    def self.managed_groups
      Config.load['mappings'].values.map { |r| r['redmine_group'] }.compact.uniq
    end

    def self.managed_project_roles
      res = {}
      Config.load['mappings'].values.each do |rules|
        next unless rules['projects']
        rules['projects'].each do |pid, pdata|
          res[pid] ||= Set.new
          pdata['roles'].each { |r| res[pid] << r }
        end
      end
      res
    end
  end
end
