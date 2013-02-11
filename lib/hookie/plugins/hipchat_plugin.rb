require_relative 'base_plugin'

require 'time'
require 'net/https'
require 'json'

module Hookie
  module Plugin
    class HipChatPlugin < BasePlugin
      def to_s
        "HipChat Notifier"
      end

      def should_run?
        warnings = []
        if @framework.changes.empty?
          log "No changes"
          return false
        end
        warnings << "hookie.hipchat.apikey not set!" unless @config[:apikey]
        warnings << "hookie.hipchat.room not set!" unless @config[:room]

        log warnings.join(", ") unless warnings.empty?

        warnings.empty?
      end

      def post_receive
        log "Sending message to HipChat ... "
        response = {}
        #log "Message: #{format_message}"
        response = speak format_message
        if response[:status]
          log "Message sent to HipChat"
        elsif response[:error]
          log "Message end failed: #{response[:error][:message]}"
        else
          log "Unknown response"
        end
      end

      private
      def format_message
        # Commits just pushed to <a href="repo-url">repo-name</a>:
        # hash (branch) Author: message
        message = ""
        message << "Commits just pushed to "
        message << if @framework.repo_url
          "<a href='#{@framework.repo_url}'>#{@framework.repo_name}</a>"
        else
          @framework.repo_name
        end
        message << ":<br/>"
        @framework.changes.each do |change|
          commit = change[:commit]

          message << if @framework.commit_url(commit)
            "<a href='#{@framework.commit_url(commit)}'>#{commit.id_abbrev}</a>"
          else
            "#{commit.id_abbrev}"
          end
          head_names = @framework.head_names_for_commit(commit).join(", ")
          message << " (#{head_names})" unless head_names.empty?
          message << " #{commit.author}: #{commit.short_message}"
          message << "<br/>"
        end
        message
      end

      private
      def speak(message)
        uri = URI.parse("https://api.hipchat.com/")
        http = Net::HTTP.new(uri.host, uri.port, @config[:proxyaddress], @config[:proxyport])
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new("/v1/rooms/message")
        request.set_form_data({"message" => message,
            "auth_token" => @config[:apikey],
            "room_id" => @config[:room],
            "notify" => @config[:notify] || 0,
            "from" => @config[:from] || "git"})

        JSON.parse(http.request(request).body, {symbolize_names: true})
      end

    end
  end
end