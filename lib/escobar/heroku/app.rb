module Escobar
  module Heroku
    # Class representing a heroku application
    class App
      attr_reader :client, :id
      def initialize(client, id)
        @id     = id
        @client = client
      end

      def name
        info["name"]
      end

      def info
        @info ||= client.get("/apps/#{id}")
      end
    end
  end
end
