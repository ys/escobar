module Escobar
  module Heroku
    # Class representing a heroku application
    class App
      attr_reader :client, :id
      def initialize(client, id)
        @id     = id
        @client = client
      end

      def name
        info["name"]
      end

      def info
        @info ||= client.heroku.get("/apps/#{id}")
      end

      def dashboard_url
        "https://dashboard.heroku.com/apps/#{name}"
      end

      def locked?
        response = client.heroku.get("/apps/#{id}/config-vars")
        response["id"] == "two_factor"
      end

      # Accepts either google authenticator or yubikey second_factor formatting
      def preauth(second_factor)
        !client.heroku.put("/apps/#{id}/pre-authorizations", second_factor).any?
      end

      def create_build(ref, environment, force, custom_payload)
        deployment = create_github_deployment("deploy", ref, environment,
                                              force, custom_payload)

        return({ error: deployment["message"] }) unless deployment["sha"]

        sha   = github_deployment["sha"]
        build = create_heroku_build(app.name, sha)
        create_deployment_from(app, deployment, sha, build)
      end

      # rubocop:disable Metrics/LineLength
      def create_deployment_from(app, github_deployment, sha, build)
        case build["id"]
        when "two_factor"
          description = "A second factor is required. Use your configured " \
                        "authenticator app or yubikey."
          create_github_deployment_status(github_deployment["url"], nil, "failure", description)
          { error: build["message"] }
        when Escobar::Heroku::BuildRequestSuccess
          target_url = "https://dashboard.heroku.com/apps/#{app.name}/" \
                       "activity/builds/#{build['id']}"

          create_github_deployment_status(github_deployment["url"],
                                          target_url,
                                          "pending",
                                          "Build running..")
          {
            sha: sha,
            name: name,
            repo: github_repository,
            app_id: app.name,
            build_id: build["id"],
            target_url: target_url,
            deployment_url: github_deployment["url"]
          }
        else
          { error: "Unable to create heroku build for #{name}" }
        end
      end
      # rubocop:enable Metrics/LineLength

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

      def create_github_deployment(task, ref, environment, force, extras = {})
        required_contexts = required_commit_contexts(force)

        options = {
          ref: ref,
          task: task,
          auto_merge: !force,
          payload: extras.merge(custom_deployment_payload),
          environment: environment,
          required_contexts: required_contexts
        }
        github_client.create_deployment(options)
      end

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def create_deployment_status(url, payload)
        github_client.create_deployment_status(url, payload)
      end
    end
  end
end
