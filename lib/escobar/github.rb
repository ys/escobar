module Escobar
  # Top-level class for interacting with GitHub API
  class GitHub
    attr_reader :client
    def initialize(token)
      @client = Octokit::Client.new(access_token: token)
    end

    def whoami
      client.get("/user")
    end
  end
end
