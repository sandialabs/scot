#!/bin/bash
# set -e

blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[0m' # No Color

echo -e "${yellow}Installing Perl Modules...${NC}"

for PACKAGE in "Curses::UI" "Number::Bytes::Human" "Sys::RunAlone" "Parallel::ForkManager" "DBI" "Encode" "FileHandle" "File::Temp" "File::Type" "Geo::IP" "HTML::Entities" "HTML::Scrubber" "HTML::Strip" "JSON" "Mail::IMAPClient" "Mail::IMAPClient::BodyStructure" "MongoDB" "MongoDB::GridFS" "MongoDB::GridFS::File" "MongoDB::OID" "Moose" "Moose::Role" "Moose::Util::TypeConstraints" "Net::Jabber::Bot" "Net::LDAP" "Net::SMTP::TLS" "Readonly" "Time::HiRes" "Mojo" "MojoX::Log::Log4perl" "MooseX::MetaDescription::Meta::Attribute" "DateTime::Format::Natural" "Net::STOMP::Client" "IPC::Run" "XML::Smart" "Config::Auto" "Data::GUID" "File::LibMagic" "Courriel" "List::Uniq" "Domain::PublicSuffix" "Crypt::PBKDF2" "Config::Crontab" "HTML::TreeBuilder HTML::FromText" "DateTime::Cron::Simple" "HTML::FromText" "IO::Prompt" "Proc::PID::File" "Test::Mojo" "Log::Log4perl" "File::Slurp" 

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

cpanm File::Slurp
cpanm Test::Mojo --force

echo -e "${yellow}Cleaning out .cpan folder...${NC}"
rm -rf $HOME/.cpan/build/*              \
       $HOME/.cpan/sources/authors/id   \
       $HOME/.cpan/cpan_sqlite_log.*    \
       /tmp/cpan_install_*.txt
