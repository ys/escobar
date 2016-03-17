module Escobar
  module Heroku
    # Class representing a deployable environment
    class Coupling
      attr_reader :app, :app_id, :client, :id, :name
      def initialize(client, coupling)
        @id     = coupling["id"]
        @name   = coupling["stage"]
        @app_id = coupling["app"]["id"]
        @client = client
      end

      def app
        @app ||= Escobar::Heroku::App.new(client, app_id)
      end
    end
  end
end
