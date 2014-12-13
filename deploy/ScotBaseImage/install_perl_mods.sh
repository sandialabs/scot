#!/bin/bash
# set -e

blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[0m' # No Color

echo -e "${yellow}Installing Perl Modules...${NC}"

HOME=$(pwd)
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

for PACKAGE in "Config::Auto" "Config::Crontab" "Courriel" "Crypt::PBKDF2" "Data::Dumper" "Data::GUID" "Date::Parse" "DateTime" "Domain::PublicSuffix" "Encode" "File::Copy" "File::Slurp" "File::Temp" "File::Type" "FileHandle" "FindBin" "Geo::IP" "HTML::Entities" "HTML::FromText" "HTML::TreeBuilder" "HTTP::Request::Common" "JSON" "IPC::Run" "List::Uniq" "LWP::UserAgent" "Log::Log4perl" "MIME::Base64" "Mail::IMAPClient::BodyStructure" "Mail::IMAPClient" "Mojo::Asset::File" "Mojo::Cache" "Mojo::DOM" "Mojo::JSON" "Mojo::UserAgent" "Mojolicious::Static" "MongoDB" "Moose" "MooseX::MetaDescription::Meta::Attribute" "Net::LDAP" "Net::STOMP::Client" "Number::Bytes::Human" "Parallel::ForkManager" "Proc::PID::File" "Readonly" "Redis" "Switch" "TAP::Harness" "Test::Deep" "Test::Mojo" "Test::More" "XML::Smart" "namespace::autoclean" "utf8" "DateTime::Cron::Simple"

do
    DOCRES=`perldoc -l $PACKAGE 2>/dev/null`
    if [[ -z "$DOCRES" ]]; then
       echo -e "${blue}Installing perl module $PACKAGE ${NC}"
       if [ "$PACKAGE" = "MongoDB" ]; then
          cpanm $PACKAGE --force
       else
          cpanm $PACKAGE
      fi
      if [ $? -ne 0 ]; then
        echo -e "${red}Retrying Intall of: $PACKAGE ${NC}"
        cpanm $PACKAGE
      fi
    fi
done

echo -e "${yellow}Cleaning out .cpan folder...${NC}"
rm -rf $HOME/.cpan/build/*              \
       $HOME/.cpan/sources/authors/id   \
       $HOME/.cpan/cpan_sqlite_log.*    \
       /tmp/cpan_install_*.txt
