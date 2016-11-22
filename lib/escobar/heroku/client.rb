module Escobar
  # Top-level class for interacting with Heroku API
  module Heroku
    # Top-level client for interacting with Heroku API
    class Client
      attr_reader :client, :token
      def initialize(token)
        @token = token
      end

      # mask password
      def inspect
        inspected = super
        inspected = inspected.gsub! @token, "*******" if @token
        inspected
      end

      def get(path, version = 3)
        response = client.get do |request|
          request.url path
          request.headers["Accept"] = heroku_accept_header(version)
          request.headers["Accept-Encoding"] = ""
          request.headers["Content-Type"]    = "application/json"
          request.headers["Authorization"]   = "Bearer #{token}"
        end

        JSON.parse(response.body)
      rescue StandardError
        response && response.body
      end

      def get_range(path, range, version = 3)
        response = client.get do |request|
          request.url path
          request.headers["Accept"] = heroku_accept_header(version)
          request.headers["Accept-Encoding"] = ""
          request.headers["Content-Type"]    = "application/json"
          request.headers["Authorization"]   = "Bearer #{token}"
          request.headers["Range"]           = range
        end

        JSON.parse(response.body)
      rescue StandardError
        response && response.body
      end

      def post(path, body)
        response = client.post do |request|
          request.url path
          request.headers["Accept"] = heroku_accept_header(3)
          request.headers["Accept-Encoding"] = ""
          request.headers["Content-Type"]    = "application/json"
          if token
            request.headers["Authorization"] = "Bearer #{token}"
          end
          request.body = body.to_json
        end

        JSON.parse(response.body)
      rescue StandardError
        response && response.body
      end

      def put(path, second_factor = nil)
        response = client.put do |request|
          request.url path
          request.headers["Accept"] = heroku_accept_header(3)
          request.headers["Accept-Encoding"] = ""
          request.headers["Content-Type"]    = "application/json"
          request.headers["Authorization"]   = "Bearer #{token}"
          if second_factor
            request.headers["Heroku-Two-Factor-Code"] = second_factor
          end
        end

        JSON.parse(response.body)
      rescue StandardError
        response && response.body
      end

      private

      def heroku_accept_header(version)
        "application/vnd.heroku+json; version=#{version}"
      end

      def client
        @client ||= Faraday.new(url: "https://api.heroku.com")
      end
    end
  end
end
