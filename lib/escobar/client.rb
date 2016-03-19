module Escobar
  # Top-level client for heroku
  class Client
    def self.from_environment
      new(Escobar.github_api_token, Escobar.heroku_api_token)
    end

    attr_reader :github_token, :heroku
    def initialize(github_token, heroku_token)
      @github_token = github_token
      @heroku = Escobar::Heroku::Client.new(heroku_token)
    end

    # mask password
    def inspect
      inspected = super
      inspected = inspected.gsub! @github_token, "*******" if @github_token
      inspected
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
  end
end
