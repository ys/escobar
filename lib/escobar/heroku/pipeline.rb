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
          id: id,
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

      def github_archive_link(ref)
        github_client.archive_link(ref)
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(client.github_token,
                                                       github_repository)
      end

      def custom_deployment_payload
        { name: name, pipeline: self.to_hash, provider: "slash-heroku" }
      end

      def create_github_deployment(task, ref, environment, force = false, extras = {})
        options = {
          ref: ref,
          task: task,
          environment: environment,
          required_contexts: [],
          auto_merge: !force,
          payload: extras.merge(custom_deployment_payload)
        }
        github_client.create_deployment(options)
      end

      def create_github_deployment_status(deployment_url, name, build_id, state)
        path    = "/apps/#{name}/activity/builds/#{build_id}"
        payload = {
          state: state,
          target_url: "https://dashboard.heroku.com#{path}",
          description: "Deploying from escobar-#{Escobar::VERSION}"
        }
        github_client.create_deployment_status(deployment_url, payload)
      end

      def create_heroku_build(app_name, sha)
        body = {
          source_blob: {
            url: github_archive_link(sha),
            version: sha[0..7],
            version_description: "#{github_repository}:#{sha}"
          }
        }
        client.heroku.post("/apps/#{app_name}/builds", body)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/LineLength
      def create_deployment(ref, environment, force)
        app = environments[environment] && environments[environment].last
        return({ error: "No '#{environment}' environment for #{name}." }) unless app

        github_deployment = create_github_deployment("deploy", ref, environment, force)
        return({ error: github_deployment["message"] }) unless github_deployment["sha"]

        build = create_heroku_build(app.name, github_deployment["sha"])
        return({ error: "Unable to create heroku build for #{name}" }) unless build["id"]

        create_github_deployment_status(github_deployment["url"], app.name, build["id"], "pending")
        { app_id: app.name, build_id: build["id"], deployment_url: github_deployment["url"] }
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
