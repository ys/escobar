require "netrc"
require "faraday"
require "octokit"
require "json"
require "escobar/version"

# Top-level module for Escobar code
module Escobar
  def self.netrc
    @netrc ||= begin
                 if env_netrc
                   env_netrc
                 else
                   home_netrc
                 end
               end
  end

  def self.env_netrc
    @env_netrc ||= begin
                     if ENV["NETRC"]
                       Netrc.read("#{ENV['NETRC']}/.netrc")
                     end
                   rescue Errno::ENOTDIR
                     nil
                   end
  end

  def self.home_netrc
    @home_netrc ||= begin
                      if ENV["HOME"]
                        Netrc.read("#{ENV['HOME']}/.netrc")
                      end
                    rescue Errno::ENOTDIR
                      nil
                    end
  end

  def self.heroku_api_token
    netrc["api.heroku.com"]["password"]
  end

  def self.github_api_token
    netrc["api.github.com"]["password"]
  end
end

require_relative "./escobar/client"
require_relative "./escobar/github"
require_relative "./escobar/heroku"
