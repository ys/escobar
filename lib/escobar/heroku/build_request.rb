module Escobar
  module Heroku
    # Class representing a heroku build request
    class BuildRequest
      attr_reader :app, :custom_payload, :environment, :forced, \
                  :github_deployment_url, :pipeline, :ref, :sha

      def initialize(pipeline, app, ref, forced, custom_payload)
        @app            = app
        @ref            = ref
        @forced         = forced
        @pipeline       = pipeline
        @custom_payload = custom_payload
      end

      def create(task = "deploy", environment = "production")
        @environment = environment

        create_github_deployment(task)

        unless sha
          raise ArgumentError, "Unable to create GitHub deployments for " \
                               "#{github_repository}: #{build['message']}"
        end

        build = create_heroku_build
        if build["id"] =~ Escobar::UUID_REGEX
          process_heroku_build(build)
        else
          raise ArgumentError, "Unable to create heroku build for " \
                               "#{app.name}: #{build['message']}"
        end
      end

      def process_heroku_build(build)
        heroku_build = Escobar::Heroku::Build.new(
          app.client, app, build["id"]
        )

        create_github_pending_deployment_status(heroku_build)

        heroku_build.github_url = github_deployment_url
        heroku_build.pipeline_name = pipeline.name
        heroku_build.sha = sha

        heroku_build
      end

      def create_heroku_build
        body = {
          source_blob: {
            url: github_client.archive_link(sha),
            version: sha[0..7],
            version_description: "#{pipeline.github_repository}:#{sha}"
          }
        }
        app.client.heroku.post("/apps/#{app.name}/builds", body)
      end

      def create_github_deployment(task)
        options = {
          ref: ref,
          task: task,
          auto_merge: !forced,
          payload: custom_payload.merge(custom_deployment_payload),
          environment: environment,
          required_contexts: required_commit_contexts
        }
        response = github_client.create_deployment(options)

        @sha = response["sha"]
        @github_deployment_url = response["url"]

        response
      end

      def create_deployment_status(url, payload)
        github_client.create_deployment_status(url, payload)
      end

      def create_github_pending_deployment_status(heroku_build)
        create_github_deployment_status(
          github_deployment_url,
          heroku_build.dashboard_build_output_url,
          "pending",
          "Build running.."
        )
      end

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def custom_deployment_payload
        { name: app.name, pipeline: pipeline.to_hash, provider: "slash-heroku" }
      end

      def required_commit_contexts
        return [] if forced
        github_client.required_contexts.map do |context|
          if context == "continuous-integration/travis-ci"
            context = "continuous-integration/travis-ci/push"
          end
          context
        end
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(
          app.client.github_token,
          pipeline.github_repository
        )
      end
    end
  end
end
