require_relative "base_plugin"

module GitoliteHooks
  module Plugin
    class EmptyPlugin < BasePlugin
      def run
        log "Empty Plugin"
      end
    end
  end
end