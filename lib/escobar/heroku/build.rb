module Escobar
  module Heroku
    # Class representing a heroku build
    class Build
      attr_reader :app_id, :client, :id

      attr_accessor :github_url
      attr_accessor :pipeline_name
      attr_accessor :sha

      def initialize(client, app_id, id)
        @id            = id
        @app_id        = app_id
        @client        = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/builds/#{id}")
      end

      def dashboard_build_output_url
        "https://dashboard.heroku.com/apps/#{app_id}/activity/builds/#{id}"
      end

      def repository_regex
        %r{https:\/\/api\.github\.com\/repos\/([-_\.0-9a-z]+\/[-_\.0-9a-z]+)}
      end

      def repository
        github_url.match(repository_regex)[1]
      end
    end
  end
end
