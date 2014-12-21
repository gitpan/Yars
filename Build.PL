BEGIN {
  unless(eval q{ use 5.010001; 1}) {
    print "Perl 5.010001 or better required\n";
    exit;
  }
}

use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use My::ModuleBuild;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601",
    "perl" => "5.010001"
  },
  "dist_abstract" => "Yet Another RESTful-Archive Service",
  "dist_author" => [
    "Graham Ollis <plicease\@cpan.org>"
  ],
  "dist_name" => "Yars",
  "dist_version" => "1.04",
  "license" => "perl",
  "module_name" => "Yars",
  "recommends" => {
    "EV" => 0
  },
  "recursive_test_files" => 1,
  "requires" => {
    "Clustericious" => "0.9940",
    "Clustericious::Client" => 0,
    "Clustericious::Client::Command" => 0,
    "Clustericious::Commands" => 0,
    "Clustericious::Config" => "0.21",
    "Clustericious::Log" => "0.11",
    "Exporter" => 0,
    "File::Find::Rule" => 0,
    "File::HomeDir" => "0.91",
    "Hash::MoreUtils" => 0,
    "IO::Uncompress::Gunzip" => 0,
    "JSON::XS" => 0,
    "List::MoreUtils" => 0,
    "Log::Log4perl" => 0,
    "Log::Log4perl::CommandLine" => 0,
    "Mojolicious" => "5.48",
    "Number::Bytes::Human" => "0.09",
    "base" => 0,
    "perl" => "5.010001"
  },
  "script_files" => [
    "bin/yars",
    "bin/yarsclient",
    "bin/yars_fast_balance",
    "bin/yars_generate_diskmap",
    "bin/yars_disk_scan"
  ],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "Test::Clustericious::Cluster" => "0.08",
    "Test::Clustericious::Config" => 0,
    "Test::Clustericious::Log" => 0,
    "Test::More" => "0.94",
    "YAML::XS" => 0,
    "perl" => "5.010001"
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "Module::Build" => "0.3601",
  "Test::Clustericious::Cluster" => "0.08",
  "Test::Clustericious::Config" => 0,
  "Test::Clustericious::Log" => 0,
  "Test::More" => "0.94",
  "YAML::XS" => 0,
  "perl" => "5.010001"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = My::ModuleBuild->new(%module_build_args);

$build->create_build_script;
