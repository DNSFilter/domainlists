require 'net/http'
require 'uri'
require 'json'

apps = {}

Dir.chdir(File.join(Dir.pwd,'applications'))
Dir.glob('*') do |filename|
  ext = File.extname(filename)
  next unless %w[.allowlist .blocklist].include?(ext)

  content = IO.readlines(filename, chomp: true) rescue nil
  next if content.nil? || content.size == 0

  content = content.map(&:strip).keep_if { |val| !val.empty? }

  app = File.basename(filename, '.*')
  apps[app] = { name: app, allow_domains: [], block_domains: [] } unless apps.key?(app)

  key = case ext
        when '.allowlist' then :allow_domains
        when '.blocklist' then :block_domains
        end
  apps[app][key] = content
end

if apps.empty?
  puts 'No applications found :|'
  exit(0)
end

puts "Applications found: #{apps.keys.join(', ')}"

api_url = URI("#{ENV['API_URL']}/v1/applications/batch_update") rescue nil
if api_url.nil? || !(api_url.is_a?(URI::HTTP) || api_url.is_a?(URI::HTTPS))
  puts 'Invalid ENV var API_URL, please check settings'
  exit(1)
end

resp = begin
  Net::HTTP.start(api_url.host, api_url.port, use_ssl: api_url.scheme == 'https') do |client|
    request = Net::HTTP::Post.new(api_url, 'Content-Type' => 'application/json')
    request['Authorization'] = "Bearer #{ENV['SECRET_TOKEN']}"
    request.body = { applications: apps.values }.to_json
    client.request(request)
  end
rescue StandardError => e
  puts "Error while trying to send request to API, error => #{e.message}"
  exit(1)
end

success = resp.code.to_i == 200 ? 0 : 1

puts "API did not reply with success status code, code: #{resp.code}, body => #{resp.body}" if success != 0
exit(success)
