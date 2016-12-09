#!/bin/bash

DISTRO=`../etcsrc/install/determine_os.sh | cut -d ' ' -f 2`;

echo "============== PERL Module Installer ============== ";
if [ $DISTRO != "RedHat" ]; then
    echo "- removing evil ubuntu version"
    apt-get remove cpanminus
    apt-get install make
fi

echo "+ getting latest cpanminus"
curl -L http://cpanmin.us | perl - --sudo App::cpanminus

WCPP=`which cpanm`

if [ "$WCPP" == "/usr/bin/cpanm" ]; 
then
    echo "! WRONG CPAN !";
    exit 1
fi

export PERL_LWP_SSL_VERIFY_HOSTNAME=0
CPANOPTS="--verbose"
# CPANOPTS="--verbose --no-check-certificate --mirror-only"
# CPANMIRROR="--mirror https://stratopan.com/toddbruner/Scot-deps/master"
CPANMIRROR=""
CPAN="/usr/local/bin/cpanm $CPANOPTS $CPANMIRROR"

echo "= using $CPAN"

LIBS='
    Moose
    Moose::Role
    Moose::Util::TypeConstraints
    MooseX::MetaDescription::Meta::Attribute
    MooseX::Singleton
    MooseX::Emulate::Class::Access
    MooseX::Types
    MooseX::Types::Common
    MooseX::MethodAttributes
    Server::Starter
    PSGI
    Plack
    CGI::PSGI
    CGI::Emulate::PSGI
    CGI::Compile
    HTTP::Server::Simple::PSGI
    JSON
    Number::Bytes::Human
    Sys::RunAlone
    Parallel::ForkManager
    DBI
    Encode
    FileHandle
    File::Slurp
    File::Temp
    File::Type
    GeoIP2
    HTML::Entities
    HTML::Scrubber
    HTML::Strip
    HTML::StripTags
    JSON
    Log::Log4perl
    Mail::IMAPClient
    Mail::IMAPClient::BodyStructure
    MongoDB@1.2.3
    MongoDB::GridFS@1.2.3
    MongoDB::GridFS::File@1.2.3
    MongoDB::OID@1.2.3
    Meerkat
    Net::Jabber::Bot
    Net::LDAP
    Net::SMTP::TLS
    Readonly
    Time::HiRes
    Mojo
    MojoX::Log::Log4perl
    DateTime::Format::Natural
    Net::STOMP::Client
    IPC::Run
    XML::Smart
    Config::Auto
    Data::GUID
    Redis
    File::LibMagic
    List::Uniq
    Domain::PublicSuffix
    Crypt::PBKDF2
    Config::Crontab
    HTML::TreeBuilder
    HTML::FromText
    DateTime::Cron::Simple
    DateTime::Format::Strptime
    HTML::FromText
    IO::Prompt
    Proc::PID::File
    Test::Mojo
    Log::Log4perl
    File::Slurp
    AnyEvent
    AnyEvent::STOMP::Client
    AnyEvent::ForkManager;
    Mozilla::PublicSuffix
    Net::IDN::Encode
    MIME::Base64
    Net::Stomp
    Proc::InvokeEditor
    Test::JSON
    Math::Int128
    Net::Works::Network
    MaxMind::DB::Reader::XS
    Data::Dumper
    Data::Dumper::HTML
    Data::Dumper::Concise
    Safe
    Search::Elasticsearch
    Data::Clean::FromJSON
    Term::ANSIColor
    Courriel
    Daemon::Control
'

for i in $LIBS
do
    echo "----------- Attempting Install of $i -------------"
    $CPAN $i
    if [ $? == 1 ]; then
        echo "!!! ERROR installing $i !!!";
        echo "+ pushing onto retry list";
        RETRY="$RETRY $i"
    fi
    echo ""
done

for i in $RETRY
do
    echo "===== RETRYING $i =====";
    $CPAN $i
    if [ $? == 1 ]; then
        echo "!!! FAILED RETRY of $i !!!";
        FAILED="$FAILED $i"
    fi
    echo ""
done

echo "~~~~~~~~~~~ Failed Perl Modules ~~~~~~~~~~~~~~";
for i in $FAILED
do
    echo "- $i"
done
