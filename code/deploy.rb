#!/opt/puppetlabs/puppet/bin/ruby

require 'net/http'
require 'uri'
require 'json'
require 'puppet'
require 'yaml'

@certname       = Puppet.settings[:certname]
@tokendir       = '/etc/puppetlabs/puppetserver/.puppetlabs/'
@classifier_url = "https://#{@certname}:4433/rbac-api/v1"
@codemgr_url    = "https://#{@certname}:8170/code-manager/v1"
@hostcert       = File.read("/etc/puppetlabs/puppet/ssl/certs/#{@certname}.pem")
@key            = File.read("/etc/puppetlabs/puppet/ssl/private_keys/#{@certname}.pem")
@cacert         = '/etc/puppetlabs/puppet/ssl/ca/ca_crt.pem'
@data           = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/data.yaml")

def do_https(endpoint, data, api = @classifier_url, method = 'post')
  url  = "#{api}/#{endpoint}"
  uri  = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)

  if uri.scheme == 'https'
    http.use_ssl     = true
    http.cert        = OpenSSL::X509::Certificate.new(@hostcert)
    http.key         = OpenSSL::PKey::RSA.new(@key)
    http.ca_file     = @cacert
    http.verify_mode = OpenSSL::SSL::VERIFY_CLIENT_ONCE
  end

  req              = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
  req.body         = data.to_json
  req.content_type = 'application/json'
  res              = http.request(req)
end

def output(raw, level='info')
  begin
    msg  = false
    jmsg = JSON.parse(raw.body)
  rescue
    msg  = raw.body
    jmsg = false
  end
  if level == 'error'
    puts JSON.pretty_generate(jmsg) if jmsg
    raise "Code #{raw.code}"
    raise msg if msg
  else
    puts JSON.pretty_generate(jmsg) if jmsg
    puts msg if msg
  end
end

# Look up permission types
#types = do_https('types', {}, @classifier_url, 'get')
#output types

def api_call(
  description,
  endpoint,
  data,
  api,
  good_codes = ['200'], 
  exist_codes = ['409'],
  verbose = false,
  method = 'post'
)
  puts "== Enforcing #{description}"
  resp = do_https(endpoint, data, api, method)

  if exist_codes.include?(resp.code)
    puts "#{description} already exists"
  elsif ! good_codes.include?(resp.code)
    puts resp['Location'] if resp.code == '302'
    output(resp, 'error')
  else
    puts "Added new #{description.downcase}"
    output(resp) if verbose
  end
  resp
end

new_role  = api_call('Role', "roles/#{@data['deploy_role']['id']}", @data['deploy_role'], @classifier_url, ['200'], ['409'], false, 'put')
new_user  = api_call('User','users', @data['deploy_user'], @classifier_url, ['303'], ['409'])
new_token = api_call('Token', 'auth/token', @data['deploy_token'], @classifier_url, ['200'], ['401'])

token     = JSON.load(new_token.body)['token']
`mkdir -p #{@tokendir}`
File.open("#{@tokendir}/deploy_token", 'w') { |file| file.write(token) }
`mkdir -p #{Dir.home}/.puppetlabs && touch ~/.puppetlabs/token`
File.open("#{Dir.home}/.puppetlabs/token", 'w') { |file| file.write(token) }

new_now = api_call('Code Deploy', "deploys?token=#{token}", @data['deploy_now'], @codemgr_url, ['200'], [], true)
