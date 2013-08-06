# LiveFlare
Automatically updates a CloudFlare zone entry with the WAN IP of a Livebox, 
without resorting to an external service such as checkip.dyndns.org 
that limits the number of calls you can make.

It uses [mechanize](https://github.com/sparklemotion/mechanize) 
to crawl [http://livebox](http://livebox)
which points to [http://192.168.1.1](http://192.168.1.1), Livebox's admin panel, 
that knows the WAN IP of your connexion (a.k.a external IP)

And the [CloudFlare API](http://www.cloudflare.com/docs/host-api.html)
to ensure the IP there is up to date.

It effectively replaces [ddclient](http://sourceforge.net/apps/trac/ddclient/),
which is a great tool but wasn't working properly for me.

## What's the point?
With this tool, you can make turn any PC in your home as a web server, 
hosting a website or anything you want, without the fees sometimes associated
with a static IP (when it is at all possible!).<br>
Whenever your Livebox renews its WAN IP, your CloudFlare DNS record 
is updated to point to it. At no cost.

I use it to host [baboon.io](http://baboon.io)

## What do I need?
* A CloudFlare account (I use the free plan, 
but it's a very neat service if you have bigger plans - pun intended), 
the associated email/API key and the name of the zone record you want to keep sync'd.
* A LiveBox like [this one](http://boutique.orange.fr/media-cms/mediatheque/livebox-incluse-4497.jpg)
 -- although it make work with other models.
 
## Options
    Usage: liveflare.rb [options]
    For informations about CloudFlare's API, visit: http://www.cloudflare.com/docs/host-api.html
        -h, --help                       Display this screen
        -a, --api-token [TOKEN]          Set CloudfFlare API token (REQUIRED)
        -e, --api-email [EMAIL]          Set CloudFlare account email (REQUIRED)
        -z, --api-zone [ZONE]            Set CloudFlare zone (REQUIRED) ex: baboon.io
        -s, --password [PASSWORD]        Livebox's admin password (defaults to 'admin')
        -i, --interval [SECONDS]         Time to wait between IP checks (defaults to 30)
        -p, --pid-file [FILE]            Path to the PID file to use (defaults to /var/run/liveflare.pid)
        -d, --[no-]daemon                If defined, the main loop runs daemonized
        -q, --quiet                      If defined, the script runs without outputing anything
        -t, --test                       If defined, tests getting server's ip from the livebox and cloudflare then outputs them along with cloudflare's zone record

## Installing and configuring
    mkdir liveflare && cd liveflare
    git clone git@github.com:LouisKottmann/liveflare.git
    bundle install
    ruby liveflare.rb \
        -a CLOUDFLARE_API_TOKEN \
        -e CLOUDFLARE_ACCOUNT_EMAIL \
        -z CLOUDFLARE_ZONE_RECORD \
        -t

This will make a test run.<br>
If this outputs the Livebox's WAN IP, CloudFlare's current IP in your DNS entry there,
and a bunch of informations about the zone record, the configuration is fine. 
You can then make it run without `-t` and maybe with other options.

Tip: I use it through a systemd service in ArchLinux on my RaspberryPi so it's always running on my server.

*Happy serving!*

    
