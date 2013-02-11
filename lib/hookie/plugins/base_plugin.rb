module Hookie
  class BasePlugin
    def initialize(framework)
      @framework = framework

      @config = {}
      @framework.config.map do |k,v|
        if k.start_with?("hookie.#{self.config_key}")
          @config[k.split(".")[2..-1].join("_").to_sym] = v
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

    private
    def plugin_name
      @plugin_name ||= self.class.to_s[/.*::(\w+)Plugin/, 1]
    end

  end
end