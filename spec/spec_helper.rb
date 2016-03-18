$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "base64"
require "escobar"
require "fileutils"
require "pry"
require "uuid"
require "webmock/rspec"

tmp_directory = File.expand_path("../../tmp", __FILE__)
FileUtils.mkdir_p tmp_directory
ENV["NETRC"] = tmp_directory
ENV["KOLKRABBI_HOSTNAME"] = "kolkrabbit.com"

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
    WebMock.reset!
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

  def fixture_path
    "#{File.expand_path('../..', __FILE__)}/spec/fixtures"
  end

  def fixture_data(name)
    path = File.join(fixture_path, "#{name}.json")
    File.read(path)
  end

  def decoded_fixture_data(name)
    JSON.parse(fixture_data(name))
  end
end
