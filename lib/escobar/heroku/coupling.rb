module Escobar
  module Heroku
    # Class representing a deployable environment
    class Coupling
      attr_reader :app, :client, :id, :name
      def initialize(client, coupling)
        @id     = coupling["id"]
        @app    = coupling["app"]["id"]
        @name   = coupling["stage"]
        @client = client
      end
    end
  end
end
