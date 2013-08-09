require 'json'
require 'mechanize'

class LiveFlare
  def initialize
    # APIs URLs
    @livebox_auth_url = 'http://livebox/authenticate'
    @line_infos_url   = 'http://livebox/rest/SI/general'
    @cloudflare_api_url = 'https://www.cloudflare.com/api_json.html'

    # headless javascriptless browser
    @mecha = Mechanize.new

    @options = {}
    @options[:password] = 'admin'
    @options[:interval] = 30
  end

  def add_options(opts)
    @opts = opts
    opts.banner = "LiveFlare - Automatically updates a CloudFlare zone entry with the WAN IP of a Livebox\n" \
                + 'Usage: ruby liveflare.rb [OPTIONS]'

    opts.on('-a', '--api-token [TOKEN]', String, 'Set CloudfFlare API token (REQUIRED)') do |api_token|
      @options[:api_token] = api_token
    end
    opts.on('-e', '--api-email [EMAIL]', String, 'Set CloudFlare account email (REQUIRED)') do |api_email|
      @options[:api_email] = api_email
    end
    opts.on('-z', '--api-zone [ZONE]', String, 'Set CloudFlare zone (REQUIRED) ex: baboon.io') do |api_zone|
      @options[:api_zone] = api_zone
    end
    opts.on('-s', '--password [PASSWORD]', String, "Livebox's admin password",
                                                   "(default: #{@options[:password]})") do |password|
      @options[:password] = password
    end
    opts.on('-i', '--interval [SECONDS]', Integer, "Time to wait between IP checks",
                                                   "(default: #{@options[:interval]})") do |interval|
      @options[:interval] = interval
    end
    opts.on('-q', '--quiet', 'If defined, the script runs without outputing anything') do |q|
      @options[:quiet] = q
    end
    opts.on('-t', '--test', "If defined, tests getting server's ip from the livebox and cloudflare " \
                        + "then outputs them along with cloudflare's zone record") do |t|
      @options[:test] = t
    end
  end

  def missing_options?
    mandatory = [:api_token, :api_email, :api_zone]                  # Enforce the presence of
    missing = mandatory.select{ |param| @options[param].nil? }       # the -a, -e and -z switches
    unless missing.empty?
      puts " **** Missing options: #{missing.join(', ')} **** "
      puts @opts
    end
    missing.any?
  end

  def compute_options
    $stdout.instance_eval{ def write(*args) end } if @options[:quiet]

    # Params needed for every CloudFare API call
    @cloudflare_api_basic_params = {
      tkn:   @options[:api_token],
      email: @options[:api_email],
      z:     @options[:api_zone]
    }

    @livebox_admin_params = { username: 'admin', password: @options[:password] }
  end

  #
  # Dyndns logic starts here
  #
  private
  def auth_on_livebox
    @mecha.get @livebox_auth_url, @livebox_admin_params
  rescue Exception
    puts "Failed to authenticate on the Livebox! Retrying in 100s.."
    p $!, *$@
    sleep 100
    retry
  end

  def get_cloudflare_entry
    account_entries = @mecha.get @cloudflare_api_url,
                                 { a: 'rec_load_all' }.merge(@cloudflare_api_basic_params)

    account_entries_json = JSON.parse(account_entries.body)

    account_entries_json['response']['recs']['objs'].each do |entry|
      return entry if entry['name'] == @options[:api_zone]
    end

    puts "#{@options[:api_zone]}'s IP was not found in the JSON response"
    nil
  rescue Exception
    puts "Failed to query #{@options[:api_zone]}'s IP on CloudFlare!"
    p $!, *$@
    nil
  end

  def set_cloudflare_ip(cloudflare_entry, new_ip)
    @mecha.post @cloudflare_api_url,
                {
                  a: 'rec_edit',
                  id: cloudflare_entry['rec_id'],
                  type: cloudflare_entry['type'],
                  name: cloudflare_entry['name'],
                  content: new_ip,
                  service_mode: cloudflare_entry['service_mode'],
                  ttl: cloudflare_entry['ttl']
                }.merge(@cloudflare_api_basic_params)

    puts "Successfully changed #{@options[:api_zone]}'s CloudFlare IP to #{new_ip} =)"
  rescue Exception
    puts "Failed to set #{@options[:api_zone]}'s new CloudFlare IP!"
    p $!, *$@
  end

  def get_livebox_wanip
    # Get the JSON loaded when we click on "informations systeme" in the admin panel,
    line_infos_page = @mecha.get @line_infos_url,
                                 {
                                   _restDepth: '2',
                                   _restAttributes: 'getObject_parameters'
                                 }
    line_infos = JSON.parse(line_infos_page.body)

    # Output the external IP
    line_infos['children'].each do |category|
      if category['objectInfo']['key'] == 'IP'
        category['children'].each do |subcategory|
          if subcategory['objectInfo']['key'] == 'WANPPPConnection'
            subcategory['parameters'].each do |param|
              return param['value'] if param['name'] == 'ExternalIPAddress'
            end
          end
        end
      end
    end

    puts "Livebox's WANIP was not found in the JSON response"
    nil
  rescue Exception
    puts "Failed to retrieve Livebox's WANIP!"
    p $!, *$@
    nil
  end

  def run_test
    begin
      require 'pp'

      auth_on_livebox
      puts "Livebox: #{get_livebox_wanip}"
      cloudflare_entry = get_cloudflare_entry
      puts "CloudFlare: #{cloudflare_entry['content']}"
      pp cloudflare_entry
    ensure
      exit
    end
  end

  public
  def start
    if @options[:test]
      run_test
      return
    end

    #
    # MAIN LOOP
    #
    loop do
      livebox_ip = get_livebox_wanip
      cloudflare_entry = get_cloudflare_entry

      if livebox_ip                                           # LiveBox may be turned off, or we need to reauthenticate
        unless cloudflare_entry.nil?                          # CloudFlare may be down occasionally
          cloudflare_ip = cloudflare_entry['content']
          if livebox_ip != cloudflare_ip                      # If IPs don't match, update CloudFlare's zone entry
            set_cloudflare_ip cloudflare_entry, livebox_ip
          end
        end
      else
        auth_on_livebox
      end
      sleep @options[:interval]
    end
  end
end