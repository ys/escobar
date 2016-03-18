module Escobar
  module GitHub
    # Top-level class for interacting with GitHub API
    class Client
      attr_reader :client
      def initialize(token)
        @client = Octokit::Client.new(access_token: token)
      end

      def whoami
        client.get("/user")
      end

      def archive_link(name_with_owner, ref)
        client.archive_link(name_with_owner, ref: ref)
      end
    end
  end
end
