$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "escobar"
require "pry"
require "uuid"
require "webmock/rspec"

tmp_directory = File.expand_path("../../tmp", __FILE__)
ENV["NETRC"] = tmp_directory

RSpec.configure do |config|
  config.include(WebMock::API)

  config.before(:all) do
    File.open("#{ENV['NETRC']}/.netrc", File::RDWR | File::CREAT, 0600) do |fp|
      netrc_file_contents.each do |uri, entry|
        fp.write "machine #{uri}\n  login #{entry['login']}\n" \
                   "  password #{entry['password']}\n"
      end
    end
  end

  config.before do
    WebMock.disable_net_connect!
    ENV["NETRC"] = tmp_directory
  end

  def uuid
    @uuid ||= UUID.new
  end

  def netrc_file_contents
    {
      "api.heroku.com" => {
        "login" => "atmos@atmos.org",
        "password" => uuid.generate
      },
      "git.heroku.com" => {
        "login" => "atmos@atmos.org",
        "password" => uuid.generate
      },
      "api.github.com" => {
        "login" => "atmos",
        "password" => Digest::SHA1.hexdigest(Time.now.to_f.to_s)
      }
    }
  end
end
