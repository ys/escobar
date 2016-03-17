module Escobar
  # Top-level client for heroku
  class Client
    def self.from_environment
      new(Escobar.github_api_token, Escobar.heroku_api_token)
    end

    attr_reader :github, :heroku
    def initialize(github_token, heroku_token)
      @github = Escobar::GitHub.new(github_token)
      @heroku = Escobar::Heroku.new(heroku_token)
    end

    def apps
      pipelines.map do |pipeline|
        { id: pipeline.id, name: pipeline.name }
      end
    end

    def pipelines
      heroku.get("/pipelines")
    end
  end
end
