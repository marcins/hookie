module Hookie
  class BasePlugin

    attr_reader :config

    def initialize(framework)
      @framework = framework

      @config = {}
      @framework.config.keys() do |k|
        if k.start_with?("hookie.#{self.config_key}")
          @config[k.split(".")[2..-1].join("_").to_sym] = @framework.config[k]
        end
      end

    end

    def log(message)
      @framework.log(self, message)
    end

    def should_run?
      true
    end

    def to_s
      plugin_name
    end

    def config_key
      plugin_name.downcase
    end

    protected
    def plugin_name
      @plugin_name ||= self.class.to_s[/(.*::)?(\w+)Plugin/, 2]
    end

  end
end