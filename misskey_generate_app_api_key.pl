#!/usr/bin/perl

use v5.16.0;

use utf8;
use strict;
use warnings;

use Encode qw(encode_utf8);
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use Digest::SHA qw(sha256_hex);

my $instanceUrl = 'https://example.com';
my $appSecret   = $ARGV[0],
my $token;

my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

unless (defined $ARGV[0]) {
   say "usage: $0 <app secret>";
   exit 1;
}

my $ua = LWP::UserAgent->new();

generate();
say "AFTER you have authorized the application press ENTER.";
<STDIN>;
userkey();

sub generate {
   my $req = HTTP::Request->new('POST', $instanceUrl . '/api/auth/session/generate', $header, encode_utf8(encode_json({appSecret => $appSecret})));
   my $res = $ua->request($req);
   my $nfo = decode_json($res->decoded_content);

   if (defined $$nfo{error}) {
      say "Error: $$nfo{error}";
      exit 2;
   }

   $token = $$nfo{token};
   say "Please visit $$nfo{url} and authorize the application.";
}

sub userkey {
   my $req = HTTP::Request->new('POST', $instanceUrl . '/api/auth/session/userkey', $header, encode_utf8(encode_json({appSecret => $appSecret, token => $token})));
   my $res = $ua->request($req);
   my $nfo = decode_json($res->decoded_content);

   if (defined $$nfo{error}) {
      say "Error: $$nfo{error}";
      exit 3;
   }

   say 'YOUR API KEY: ' . lc(sha256_hex($$nfo{accessToken}.$appSecret));
}
