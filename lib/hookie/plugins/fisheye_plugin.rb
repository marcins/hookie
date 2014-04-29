require_relative 'base_plugin'

require 'time'
require 'net/https'
require 'json'

module Hookie
  module Plugin
    class FishEyePlugin < BasePlugin
      def to_s
        "FishEye Notifier"
      end

      def should_run?
        warnings = []
        if @framework.changes.empty?
          log "No changes"
          return false
        end
        warnings << "hookie.fisheye.apikey not set!" unless @config[:apikey]
        warnings << "hookie.fisheye.url not set!" unless @config[:url]

        log warnings.join(", ") unless warnings.empty?

        warnings.empty?
      end

      def post_receive
        log "Sending scan request to FishEye ... "
        response = notify()
        if response == []
          log "Request sent to FishEye"
        elsif response[:message]
          log "Error: #{response[:message]}"
        else
          log "Unknown response #{response}"
        end
      end

      private
      def notify
        uri = URI.parse(@config[:url].gsub('%REPO%', @framework.repo_name))
        http = Net::HTTP.new(uri.host, uri.port, @config[:proxyaddress], @config[:proxyport])
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(uri.path)
        request['X-Api-Key'] = @config[:apikey]

        JSON.parse(http.request(request).body, {symbolize_names: true})
      end

    end
  end
end