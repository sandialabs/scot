FROM ubuntu:16.04

ARG HTTPS_PROXY
ARG HTTP_PROXY
ARG https_proxy
ARG http_proxy
ARG no_proxy

ENV https_proxy=${https_proxy}
ENV http_proxy=${http_proxy}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=${no_proxy}
ENV NO_PROXY=${NO_PROXY}
ENV no_proxy="elastic,mongodb,scot,activemq,apache"
ENV NO_PROXY="elastic,mongodb,scot,activemq,apache"

COPY docker-configs/perl/ /opt/scot/perl/

RUN apt-get update && \
    apt-get -qy upgrade && \
    apt-get install -qy software-properties-common perl build-essential cpanminus perl-doc perl-base perl-modules curl vim ssmtp && \
    cat /opt/scot/perl/libs.txt | xargs apt-get install -qy && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*, /tmp/*, /var/tmp/* 
  
RUN add-apt-repository http://ppa.launchpad.net/maxmind/ppa/ubuntu  && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D68FA50FEA312927 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated libgeoip-dev libmaxminddb0 libmaxminddb-dev mmdb-bin pwgen mongodb-org-shell mongodb-org-tools  && \
    echo "mongodb-org-shell hold" | dpkg --set-selections 

#Install CPAN modules
COPY docker-scripts/install_perl_modules.sh /opt/scot/perl/
#RUN bash /opt/scot/perl/install_perl_modules.sh  

RUN cpanm --force  Array::Split Data::Dumper Data::Dumper::HTML Data::Dumper::Concise Data::Clean Data::Clean::FromJSON Daemon::Control Net::LDAP Net::SMTP::TLS Net::Stomp \ 
Net::STOMP::Client Net::IDN::Encode Net::Works::Network Net::IP Moose Moose::Role Moose::Util::TypeConstraints MooseX::MetaDescription::Meta::Attribute MooseX::Singleton \ 
MooseX::Emulate::Class::Accessor::Fast MooseX::Types MooseX::Types::Common MooseX::MethodAttributes MooseX::Role::MongoDB@0.010 Safe Readonly DateTime DateTime::Cron::Simple \ 
DateTime::Format::Strptime DateTime::Format::Natural Time::HiRes Server::Starter PSGI CGI::PSGI CGI::Compile HTTP::Server::Simple::PSGI JSON JSON::XS DBI Parallel::ForkManager \ 
AnyEvent AnyEvent::STOMP::Client AnyEvent::ForkManager Async::Interrupt Number::Bytes::Human Sys::RunAlone Encode FileHandle File::Slurp File::Temp File::Type MIME::Base64 \ 
IPC::Run IO::Prompt  Log::Log4perl Mail::IMAPClient Mail::IMAPClient::BodyStructure MongoDB@1.8.3 MongoDB::GridFS@1.8.3 MongoDB::GridFS::File@1.8.3 MongoDB::OID@1.8.3 \
Alien::GMP Meerkat Mojo MojoX::Log::Log4perl Mojolicious::Plugin::WithCSRFProtection Mojolicious::Plugin::TagHelpers XML::Smart Config::Auto Data::GUID File::LibMagic List::Uniq \ 
Domain::PublicSuffix Mozilla::PublicSuffix Crypt::PBKDF2 Config::Crontab Math::Int128 GeoIP2 Search::Elasticsearch Term::ANSIColor \ 
Courriel Statistics::Descriptive Net::SSH::Perl Net::SFTP Lingua::Stem Math::VecStat Class::Exporter Math::HashSum Math::Vector::SortIndexes Lingua::EN::StopWords \ 
XML::Twig XML::Simple SVG::Sparkline Email::Stuffer HTML::Entities HTML::Scrubber HTML::Strip HTML::StripTags HTML::TreeBuilder HTML::FromText HTML::FormatText 

#problem modules that should be run last
RUN cpanm MaxMind::DB::Reader::XS 

COPY lib/ /opt/scot/lib/
COPY bin/ /opt/scot/bin/

#install geoip 

RUN mkdir mkdir /usr/local/share/GeoIP/ && \
    touch /usr/local/share/GeoIP/GeoLiteCity.dat  





