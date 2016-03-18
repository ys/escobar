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

      def sorted_environments
        environments.keys.sort
      end

      def environments
        @environments ||= couplings.each_with_object({}) do |part, sum|
          sum[part.stage] ||= []
          sum[part.stage].push(part)
          sum
        end
      end

      def environment_hash
        sorted_environments.each_with_object({}) do |environment, sum|
          sum[environment.to_sym] = environments[environment].map(&:to_hash)
          sum
        end
      end

      def to_hash
        {
          name: name,
          github_repository: github_repository,
          environments: environment_hash
        }
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
        client.heroku.get("/pipelines/#{id}/pipeline-couplings").map do |pc|
          Escobar::Heroku::Coupling.new(client, pc)
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/LineLength
      # rubocop:disable Metrics/MethodLength
      def create_deployment(ref, environment, force)
        deployment             = Escobar::GitHub::Deployment.new(client.github.client)
        deployment.ref         = ref
        deployment.repo        = github_repository
        deployment.force       = force
        deployment.environment = environment

        archive_link = deployment.archive_link

        payload = self.to_hash
        payload[:name] = name
        payload[:provider] = "slash-heroku"

        github_deployment = deployment.create(payload)
        body = {
          source_blob: {
            url: archive_link,
            version: github_deployment.sha[0..7],
            version_description: "#{deployment.repo}:#{github_deployment.sha}"
          }
        }
        app = environments[environment].last
        build = client.heroku.post("/apps/#{app.name}/builds", body)
        if build["id"]
          status_payload = {
            target_url: "#{app.app.dashboard_url}/activity/builds/#{build['id']}",
            description: "Deploying from slash-heroku"
          }

          deployment.create_status(github_deployment.url, "pending", status_payload)
          {
            app_id: app.name, build_id: build["id"],
            deployment_url: github_deployment.url
          }
        end
      end

      def get(path)
        response = kolkrabbi.get do |request|
          request.url path
          request.headers["Content-Type"]  = "application/json"
          request.headers["Authorization"] = "Bearer #{client.heroku.token}"
        end

        JSON.parse(response.body)
      end

      def kolkrabbi
        @kolkrabbi ||= Faraday.new(url: "https://#{ENV['KOLKRABBI_HOSTNAME']}")
      end
    end
  end
end
