module Escobar
  module Heroku
    # Class representing a deployable environment
    class Coupling
      attr_reader :app, :app_id, :client, :id, :stage
      def initialize(client, coupling)
        @id     = coupling["id"]
        @stage  = coupling["stage"]
        @app_id = coupling["app"]["id"]
        @client = client
      end

      def app
        @app ||= Escobar::Heroku::App.new(client, app_id)
      end

      def name
        app && app.name
      end

      def to_hash
        {
          id: id,
          name: name,
          stage: stage,
          app_id: app_id
        }
      end
    end
  end
end
