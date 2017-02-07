module Escobar
  module Heroku
    # Class representing an app's dyno state
    class Dynos
      attr_reader :app_id, :client

      attr_accessor :command_id
      attr_accessor :github_url
      attr_accessor :pipeline_name

      def initialize(client, app_id)
        @app_id = app_id
        @client = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/dynos")
      end

      def all_on_release?(release_id)
        info.all? { |dyno| dyno["release"]["id"] == release_id }
      end

      def newer_than?(epoch)
        info.all? do |dyno|
          epoch < Time.parse(dyno["created_at"]).utc
        end
      end
    end
  end
end
