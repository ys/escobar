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

      def configured?
        couplings.any? && github_repository
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

      def default_environment
        sorted_environments.last
      end

      def default_branch
        github_client.default_branch
      end

      def required_commit_contexts(forced = false)
        return [] if forced
        github_client.required_contexts.map do |context|
          if context == "continuous-integration/travis-ci"
            context = "continuous-integration/travis-ci/push"
          end
          context
        end
      end

      def heroku_permalink
        "https://dashboard.heroku.com/pipelines/#{id}"
      end

      def default_branch_settings_uri
        "https://github.com/#{github_repository}/" \
          "settings/branches/#{default_branch}"
      end

      def reap_build(app_id, build_id)
        info = client.heroku.get("/apps/#{app_id}/builds/#{build_id}")
        case info["status"]
        when "succeeded", "failed"
          info
        end
      end

      def create_deployment(ref, environment, force = false, payload = {})
        app = environments[environment] && environments[environment].last.app
        if app
          if !app.locked?
            app.create_build(ref, environment, force, payload)
          else
            { error: "Application #{name} is locked by a second factor",
              url: app.dashboard_url }
          end
        else
          { error: "No '#{environment}' environment for #{name}." }
        end
      end

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

      private

      def remote_repository
        @remote_repository ||= get("/pipelines/#{id}/repository")
      end

      def custom_deployment_payload
        { name: name, pipeline: self.to_hash, provider: "slash-heroku" }
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(client.github_token,
                                                       github_repository)
      end
    end
  end
end
