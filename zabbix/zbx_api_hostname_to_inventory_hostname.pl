#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use JSON::RPC::Client;

my ($aid, $res);

my $url  = 'http://zabbix.ip/zabbix/api_jsonrpc.php';
my $user = 'admin';
my $pass = 'pass';

my $json = {
   jsonrpc => '2.0',
   method  => 'user.login',
   params  => {
      user     => $user,
      password => $pass,
   },
   id => 1,
};

my $z = JSON::RPC::Client->new;

$res = $z->call($url, $json);
die "Could not authenticate.\n" unless ($res->content->{result});

$aid = $res->content->{'result'};
print "Authentication successful, Auth ID: $aid\n\n";

$json = {
   jsonrpc => '2.0',
   method  => 'host.get',
   params  => {
      output          => ['hostid', 'host', 'name'],
      selectInventory => ['name'],
      sortfield       => 'hostid',
   },
   id   => 2,
   auth => $aid,
};

$res = $z->call($url, $json);
die "$$json{method} failed\n" unless ($res->content->{result});

my $count = 0;
my $crapcount = 0;
my @crap;

foreach my $host (@{$res->content->{result}}) {
   unless (ref $host->{inventory} eq 'ARRAY' || $host->{inventory}->{name} =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/ || $host->{inventory}->{name} eq '') {
      print "Now updating #$host->{hostid} | Old hostname: $host->{host} | New hostname: $host->{inventory}->{name}\n";

      $json = {
         jsonrpc => '2.0',
         method  => 'host.update',
         params  => {
            hostid => $host->{hostid}, 
            host   => $host->{inventory}->{name},
         },
         id   => $count+3,
         auth => $aid,
      };

      $res = $z->call($url, $json);
      warn "$$json{method} failed\n" unless ($res->content->{result});

      unless ($res->content->{result}) {
         warn "$$json{method} failed\n";
         push(@crap, $host->{hostid});
         $crapcount++;
      }
      else {
         $count++;
      }
   }
}

if (@crap) {
   print "\nCrap ($crapcount):\n";
   print "$_\n" for (@crap);
}

printf("\nUpdated %u hosts.\n", $count - $crapcount);
