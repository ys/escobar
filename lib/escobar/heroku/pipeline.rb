module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline
    class Pipeline
      attr_reader :client, :id, :name
      def initialize(client, id, name)
        @id           = id
        @name         = name
        @client       = client
      end

      def environments
        @environments ||= couplings.each_with_object({}) do |part, sum|
          sum[part.name] ||= []
          sum[part.name].push(part)
          sum
        end
      end

      def repository
        @repository ||= get("/pipelines/#{id}/repository")
      end

      def github_repository
        repository["repository"] && repository["repository"]["name"]
      end

      def couplings
        @couplings ||= couplings!
      end

      def couplings!
        client.get("/pipelines/#{id}/pipeline-couplings").map do |coupling|
          Escobar::Heroku::Coupling.new(client, coupling)
        end
      end

      def get(path)
        response = kolkrabbi.get do |request|
          request.url path
          request.headers["Content-Type"]  = "application/json"
          request.headers["Authorization"] = "Bearer #{client.token}"
        end

        JSON.parse(response.body)
      end

      def kolkrabbi
        @kolkrabbi ||= Faraday.new(url: "https://#{ENV['KOLKRABBI_HOSTNAME']}")
      end
    end
  end
end
