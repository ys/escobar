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
        @environments ||= couplings.each_with_object({}) do |sum, part|
          sum[part.name] = part
          sum
        end
      end

      def couplings
        @couplings ||= couplings!
      end

      def couplings!
        client.get("/pipelines/#{id}/pipeline-couplings").map do |coupling|
          Escobar::Heroku::Coupling.new(client, coupling)
        end
      end
    end
  end
end
