require_relative "base_plugin"

module GitoliteHooks
  module Plugin
    class EmptyPlugin < BasePlugin
      def post_receive
        log "Empty Plugin - post_receive"
      end
    end
  end
end