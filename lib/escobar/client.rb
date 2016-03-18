module Escobar
  # Top-level client for heroku
  class Client
    def self.from_environment
      new(Escobar.github_api_token, Escobar.heroku_api_token)
    end

    attr_reader :github, :heroku
    def initialize(github_token, heroku_token)
      @github = Escobar::GitHub::Client.new(github_token)
      @heroku = Escobar::Heroku::Client.new(heroku_token)
    end

    def [](key)
      pipelines.find { |pipeline| pipeline.name == key }
    end

    def app_names
      pipelines.map(&:name)
    end

    def pipelines
      @pipelines ||= heroku.get("/pipelines").map do |pipe|
        Escobar::Heroku::Pipeline.new(heroku, pipe["id"], pipe["name"])
      end
    end

    def dashboard_url(name)
      "https://dashboard.heroku.com/apps/#{name}"
    end

    def reap_deployment(heroku_app_id, heroku_build_id)
      info = heroku.get("/apps/#{heroku_app_id}/builds/#{heroku_build_id}")
      case info["status"]
      when "succeeded", "failed"
        info
      else
        false
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/LineLength
    # rubocop:disable Metrics/MethodLength
    def create_deployment(name, repo, ref, environment, force)
      deployment             = Escobar::GitHub::Deployment.new(github.client)
      deployment.ref         = ref
      deployment.repo        = repo
      deployment.force       = force
      deployment.environment = environment

      archive_link = deployment.archive_link

      pipeline = self[name]
      if pipeline
        payload = pipeline.to_hash
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

        app = pipeline.environments[environment].last

        build = heroku.post("/apps/#{app.name}/builds", body)
        if build["id"]
          status_payload = {
            target_url: "#{dashboard_url(app.name)}/activity/builds/#{build['id']}",
            description: "Deploying from slash-heroku"
          }

          deployment.create_status(github_deployment.url, "pending", status_payload)
          {
            app_id: app.name, build_id: build["id"],
            deployment_url: github_deployment.url
          }
        end
      end
    end
  end
end
