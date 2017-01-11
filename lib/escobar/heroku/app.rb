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
        @info ||= client.heroku.get("/apps/#{id}")
      end

      def dashboard_url
        "https://dashboard.heroku.com/apps/#{name}"
      end

      # Accepts either google authenticator or yubikey second_factor formatting
      def preauth(second_factor)
        !client.heroku.put("/apps/#{id}/pre-authorizations", second_factor).any?
      end

      def locked?
        response = client.heroku.get("/apps/#{id}/config-vars")
        response["id"] == "two_factor"
      end

      def build_request_for(pipeline)
        Escobar::Heroku::BuildRequest.new(pipeline, self)
      end
    end
  end
end
