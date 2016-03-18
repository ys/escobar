module Escobar
  module GitHub
    # Class to create a Deployment record on GitHub
    class Deployment
      attr_accessor :client, :environment, :force, :ref, :repo
      def initialize(client)
        @client = client
      end

      def payload(custom_payload)
        {
          task: "deploy",
          payload: custom_payload,
          auto_merge: !force,
          required_contexts: [],
          environment: "staging",
          description: "Shipped from chat with slash-heroku"
        }
      end

      def archive_link
        client.archive_link(repo, ref: ref)
      end

      def create(custom_payload)
        client.create_deployment(repo, ref, payload(custom_payload))
      end

      def create_status(url, state, extra_payload)
        client.create_deployment_status(url, state, extra_payload)
      end
    end
  end
end
