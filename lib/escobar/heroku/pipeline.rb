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

      def github_repository
        remote_repository["repository"] &&
          remote_repository["repository"]["name"]
      end

      def couplings
        @couplings ||= couplings!
      end

      def couplings!
        client.heroku.get("/pipelines/#{id}/pipeline-couplings").map do |pc|
          Escobar::Heroku::Coupling.new(client, pc)
        end
      end

      def reap_build(app_id, build_id)
        info = client.heroku.get("/apps/#{app_id}/builds/#{build_id}")
        case info["status"]
        when "succeeded", "failed"
          info
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/LineLength
      def create_deployment(ref, environment, force = false, custom_payload = {})
        app = environments[environment] && environments[environment].last
        return({ error: "No '#{environment}' environment for #{name}." }) unless app

        github_deployment = create_github_deployment("deploy", ref, environment, force, custom_payload)
        return({ error: github_deployment["message"] }) unless github_deployment["sha"]

        sha   = github_deployment["sha"]
        build = create_heroku_build(app.name, sha)
        case build["id"]
        when "two_factor"
          description = "A second factor is required. Use your configured authenticator app or yubikey."
          create_github_deployment_status(github_deployment["url"], nil, "failure", description)
          return({ error: build["message"] })
        when Escobar::Heroku::BuildRequestSuccess
          path = "/apps/#{app.name}/activity/builds/#{build['id']}"
          target_url = "https://dashboard.heroku.com#{path}"

          create_github_deployment_status(github_deployment["url"], target_url, "pending", "Build running..")
          { app_id: app.id, build_id: build["id"], deployment_url: github_deployment["url"], name: name, repo: github_repository, sha: sha }
        else
          return({ error: "Unable to create heroku build for #{name}" })
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/LineLength

      def get(path)
        response = kolkrabbi_client.get do |request|
          request.url path
          request.headers["Content-Type"]  = "application/json"
          request.headers["Authorization"] = "Bearer #{client.heroku.token}"
        end

        JSON.parse(response.body)
      end

      def kolkrabbi_client
        @kolkrabbi ||= Faraday.new(url: "https://#{ENV['KOLKRABBI_HOSTNAME']}")
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(client.github_token,
                                                       github_repository)
      end

      private

      def remote_repository
        @remote_repository ||= get("/pipelines/#{id}/repository")
      end

      def custom_deployment_payload
        { name: name, pipeline: self.to_hash, provider: "slash-heroku" }
      end

      def create_github_deployment(task, ref, environment, force, extras = {})
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

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        github_client.create_deployment_status(url, payload)
      end

      def create_heroku_build(app_name, sha)
        body = {
          source_blob: {
            url: github_client.archive_link(sha),
            version: sha[0..7],
            version_description: "#{github_repository}:#{sha}"
          }
        }
        client.heroku.post("/apps/#{app_name}/builds", body)
      end
    end
  end
end
