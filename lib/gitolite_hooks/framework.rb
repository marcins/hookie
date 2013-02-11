module Gitolite
  module Hooks
    class Framework

      require 'grit'

      attr_reader :config, :changes

      def initialize(repo_path, hook)

        @repo = Grit::Repo.new(repo_path)

        read_changes
        read_config
        run_plugins(hook)
      end

      def run_plugins(hook)
        Dir.glob(File.join(File.dirname(__FILE__),"plugins","*.rb")) do |filename|
          require filename
        end

        GitoliteHooks::Plugin.constants.each do |constant|
          clazz = GitoliteHooks::Plugin.const_get(constant)
          if clazz < GitoliteHooks::BasePlugin
            plugin = clazz.new(self)
            if @config['hooks.allowedplugins'].include?(plugin.config_key) and
              plugin.respond_to?(hook) and
              plugin.should_run?
                plugin.send(hook)
            end
          end
        end
      end

      def log(plugin, message)
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        puts "[#{timestamp}] #{plugin}: #{message}"
      end

      def repo_url
        if @config['hooks.repo.web.browse']
          @config['hooks.repo.web.browse'].gsub("%REPO%", repo_name)
        end
      end

      def commit_url(commit)
        if @config['hooks.repo.web.commit']
          @config['hooks.repo.web.commit'].gsub("%REPO%", repo_name).gsub("%COMMIT%", commit.id)
        end
      end

      def repo_name
        if @config['hooks.repo.name']
          @config['hooks.repo.name']
        elsif @repo.bare
          File.basename(@repo.path, ".git")
        else
          File.basename(File.expand_path(File.join(@repo.path, "..")))
        end
      end

      def head_names_for_commit(commit)
        @repo.heads.collect { |head| head.name if head.commit.id == commit.id }.compact
      end

      private
      def read_config
        @config = {}
        raw_config = `git config -l --local`
        raw_config.split("\n").each do |config_item|
          if config_item =~ /([^=]+)=(.*)/
            @config[$1] = $2
          end
        end
      end

      private
      def read_changes
        @changes = []
        STDIN.each_line do |line|
          parts = line.split(" ")
          @changes << {
            old_hash: parts[0],
            new_hash: parts[1],
            ref: parts[2],
            commit: @repo.commits(parts[1], 1)[0]
          }
        end
      end
    end
  end
end