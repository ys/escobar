module Escobar
  module Heroku
    # Class representing a heroku build
    class Build
      attr_reader :app_id, :app_name, :client, :id

      attr_accessor :command_id
      attr_accessor :github_url
      attr_accessor :pipeline_name
      attr_accessor :sha

      def initialize(client, app, id)
        @id            = id
        @app_id        = app.id
        @app_name      = app.name
        @client        = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/builds/#{id}")
      end

      def dashboard_build_output_url
        "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{id}"
      end

      def repository_regex
        %r{https:\/\/api\.github\.com\/repos\/([-_\.0-9a-z]+\/[-_\.0-9a-z]+)}
      end

      def repository
        github_url.match(repository_regex)[1]
      end

      def to_job_json
        {
          sha: sha,
          name: pipeline_name,
          repo: repository,
          app_id: app_id,
          app_name: app_name,
          build_id: id,
          command_id: command_id,
          target_url: dashboard_build_output_url,
          deployment_url: github_url
        }
      end
    end
  end
end
