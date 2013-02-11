module Hookie
  class Framework

    require 'grit'

    attr_reader :config, :changes

    def initialize(hook, repo_path)

      @repo = Grit::Repo.new(repo_path)
      read_changes
      read_config
      run_plugins(hook)
    end

    def run_plugins(hook)

      unless @config['hookie.core.allowedplugins']
        puts "Missing hookie.core.allowedplugins config variable!"
        exit 255
      end

      plugin_paths = $: + [File.join(File.dirname(__FILE__),"plugins")]
      plugin_paths.each do |path|
        Dir.glob(File.join(path, "*_plugin.rb")) do |filename|
          begin
            require filename
          rescue LoadError => e
            puts "Unable to load plugin #{filename}: #{e}"
          end
        end
      end

      Hookie::Plugin.constants.each do |constant|
        clazz = Hookie::Plugin.const_get(constant)
        if clazz < Hookie::BasePlugin
          plugin = clazz.new(self)
          if @config['hookie.core.allowedplugins'].include?(plugin.config_key) and
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
      if @config['hookie.core.web.browse']
        @config['hookie.core.web.browse'].gsub("%REPO%", repo_name)
      end
    end

    def commit_url(commit)
      if @config['hookie.core.web.commit']
        @config['hookie.core.web.commit'].gsub("%REPO%", repo_name).gsub("%COMMIT%", commit.id)
      end
    end

    def repo_name
      if @config['hookie.core.repo.name']
        @config['hookie.core.repo.name']
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