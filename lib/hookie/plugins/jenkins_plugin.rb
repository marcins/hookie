require_relative "base_plugin"

module Hookie
  module Plugin
    class JenkinsPlugin < BasePlugin

      def should_run?
        unless @config[:url]
          log "Jenkins URL not configured!"
          return false
        end

        if @config[:branches]
          allowed_branches = @config[:branches].split(",")
          commits = @framework.changes.map { |change| change[:commit] }
          branches = commits.collect { |commit| @framework.head_names_for_commit(commit) }
          branches.flatten!
          if (branches & allowed_branches).empty?
            log "No commits on matching branches (#{allowed_branches.join(', ')})"
            return false
          end
        end
        return true
      end

      def post_receive
        uri = URI.parse(@config[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        if @config[:auth]
          request.basic_auth(*@config[:auth].split(":"))
        end
        response = http.request(request)
        log "Response: #{response.body}"
      end
    end
  end
end