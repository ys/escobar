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
        Escobar::Heroku::Pipeline.new(self, pipe["id"], pipe["name"])
      end
    end

    def reap_deployment(heroku_app_id, heroku_build_id)
      info = heroku.get("/apps/#{heroku_app_id}/builds/#{heroku_build_id}")
      case info["status"]
      when "succeeded", "failed"
        info
      end
    end
  end
end
