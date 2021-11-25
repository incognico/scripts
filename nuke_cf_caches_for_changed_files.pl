#!/usr/bin/env perl

use 5.28.0;

use utf8;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures experimental::smartmatch);

use File::Find;
use JSON;
use LWP::UserAgent;
use YAML::XS qw(LoadFile DumpFile);

my $store = '/srv/www/cf-arch/.cf_cache_watcher';
my $www_dir = '/srv/www/cf-arch/htdocs';
my $www_web = 'https://alhp.krautflare.de';
my @watch_dirs = glob($www_dir.'/*-x86-64-v3');
my $cf_api_url = 'https://api.cloudflare.com/client/v4/zones';
my $cf_api_mail = '';
my $cf_api_key = '';
my $cf_api_zone = '';

my $oldpairs = LoadFile($store);
my ($newpairs, @to_nuke);

find(\&wanted, @watch_dirs);

sub wanted () {
   return unless -f $_;

   my $ct = (stat($File::Find::name))[10];
   $$newpairs{$File::Find::name} = $ct;

   push(@to_nuke, $www_web . substr($File::Find::name, length($www_dir))) if (exists $$oldpairs{$File::Find::name} && $$oldpairs{$File::Find::name} != $ct);
}

DumpFile($store, $newpairs);

my $content;
push($$content{files}->@*, $_) for (@to_nuke);

my $ua = LWP::UserAgent->new;
$ua->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());
$ua->default_header('Content-Type' => 'application/json');
$ua->default_header('X-Auth-Email' => $cf_api_mail);
#$ua->default_header('X-Auth-Key' => $cf_api_key); # welp api docs wrong
$ua->default_header('Authorization' => 'Bearer '.$cf_api_key);
my $res = $ua->post($cf_api_url.'/'.$cf_api_zone.'/purge_cache', Content => encode_json($content));

# maybe re-queue @to_nuke if !$res->is_success? good enough for now tho...
