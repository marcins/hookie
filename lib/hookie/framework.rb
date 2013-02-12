module Hookie

  class Framework

    require 'grit'

    attr_reader :changes

    def self.hook(hook)
      hookie = Hookie::Framework.new hook, ARGV[1] || Dir.getwd
      hookie.run_plugins(hook)
    end

    def initialize(hook, repo_path)
      @repo = Grit::Repo.new(repo_path)
      read_changes
    end

    def run_plugins(hook)
      # we are only allowed to run if the plugin is in the list of allowed
      # plugins
      unless config['hookie.core.allowedplugins']
        exit 255
      end

      Dir.glob(File.join(File.join(File.dirname(__FILE__),"plugins"), "*_plugin.rb")) do |filename|
        begin
          require filename
        rescue LoadError => e
          puts "Unable to load plugin #{filename}: #{e}"
        end
      end

      Hookie::Plugin.constants.each do |constant|
        clazz = Hookie::Plugin.const_get(constant)
        if clazz < Hookie::BasePlugin
          plugin = clazz.new(self)
          if config['hookie.core.allowedplugins'].include?(plugin.config_key) and
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
      if config['hookie.core.web.browse']
        config['hookie.core.web.browse'].gsub("%REPO%", repo_name)
      end
    end

    def commit_url(commit)
      if config['hookie.core.web.commit']
        config['hookie.core.web.commit'].gsub("%REPO%", repo_name).gsub("%COMMIT%", commit.id)
      end
    end

    def repo_name
      if config['hookie.core.repo.name']
        config['hookie.core.repo.name']
      elsif @repo.bare
        File.basename(@repo.path, ".git")
      else
        File.basename(File.expand_path(File.join(@repo.path, "..")))
      end
    end

    def head_names_for_commit(commit)
      @repo.heads.collect { |head| head.name if head.commit.id == commit.id }.compact
    end

    def config
      @repo.config
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