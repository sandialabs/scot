#!/bin/bash

function install_ubuntu_packages {

    DEBPACKAGES='
        perl
        perl-doc
        perl-base
        perl-modules
        perlmagick
        perltidy
        libcurses-perl
        libmagic-dev
        libxml-perl
        libyaml-perl
        libwww-mechanize-perl
        libjson-perl
        librose-db-perl
        libtree-simple-perl
        libtask-weaken-perl
        libtree-simple-visitorfactory-perl
        libalgorithm-c3-perl
        libapparmor-perl
        libarchive-zip-perl
        libauthen-krb5-simple-perl
        libauthen-sasl-perl
        libb-hooks-endofscope-perl
        libb-keywords-perl
        libbit-vector-perl
        libcache-perl
        libcairo-perl
        libcarp-assert-more-perl
        libcarp-assert-perl
        libcarp-clan-perl
        libcgi-simple-perl
        libcgi-emulate-psgi-perl
        libclass-accessor-perl
        libclass-c3-adopt-next-perl
        libclass-c3-perl
        libclass-c3-xs-perl
        libclass-data-inheritable-perl
        libclass-errorhandler-perl
        libclass-factory-util-perl
        libclass-inspector-perl
        libclass-singleton-perl
        libclone-perl
        libclone-pp-perl
        libcompress-bzip2-perl
        libconfig-tiny-perl
        libdata-dump-perl
        libdata-optlist-perl
        libdate-manip-perl
        libdatetime-format-builder-perl
        libdatetime-format-mysql-perl
        libdatetime-format-pg-perl
        libdatetime-format-strptime-perl
        libdatetime-locale-perl
        libdatetime-perl
        libdatetime-timezone-perl
        libdbd-mysql-perl
        libdbd-pg-perl
        libdbi-perl
        libdevel-globaldestruction-perl
        libdevel-stacktrace-perl
        libdevel-symdump-perl
        liberror-perl
        libexception-class-perl
        libextutils-autoinstall-perl
        libfcgi-perl
        libfile-copy-recursive-perl
        libfile-homedir-perl
        libfile-modified-perl
        libfile-nfslock-perl
        libfile-remove-perl
        libfile-searchpath-perl
        libfile-slurp-perl
        libfile-spec-perl
        libfile-which-perl
        libfont-afm-perl
        libfreezethaw-perl
        libglib-perl
        libgnome2-canvas-perl
        libgnome2-perl
        libgnome2-vfs-perl
        libgtk2-perl
        libheap-perl
        libhtml-clean-perl
        libhtml-format-perl
        libhtml-parser-perl
        libhtml-tagset-perl
        libhtml-template-perl
        libhtml-tree-perl
        libhttp-body-perl
        libhttp-request-ascgi-perl
        libhttp-response-encoding-perl
        libhttp-server-simple-perl
        libio-socket-ssl-perl
        libio-string-perl
        libio-stringy-perl
        libjson-perl
        libjson-xs-perl
        liblingua-stem-snowball-perl
        liblist-moreutils-perl
        liblocale-gettext-perl
        liblwp-authen-wsse-perl
        libmailtools-perl
        libmime-types-perl
        libmldbm-perl
        libmodule-corelist-perl
        libmodule-install-perl
        libmodule-scandeps-perl
        libmro-compat-perl
        libnamespace-autoclean-perl
        libnamespace-clean-perl
        libnet-daemon-perl
        libnet-dbus-perl
        libnet-jabber-perl
        libnet-libidn-perl
        libnet-ssleay-perl
        libnet-xmpp-perl
        libpango-perl
        libpar-dist-perl
        libparams-util-perl
        libparams-validate-perl
        libparse-cpan-meta-perl
        libparse-debianchangelog-perl
        libpath-class-perl
        libperl-critic-perl
        libplrpc-perl
        libpod-coverage-perl
        libpod-spell-perl
        libppi-perl
        libreadonly-perl
        libreadonly-xs-perl
        librose-datetime-perl
        librose-db-object-perl
        librose-db-perl
        librose-object-perl
        librpc-xml-perl
        libscope-guard-perl
        libscope-upper-perl
        libsphinx-search-perl
        libsql-reservedwords-perl
        libstring-format-perl
        libstring-rewriteprefix-perl
        libsub-exporter-perl
        libsub-install-perl
        libsub-name-perl
        libsub-uplevel-perl
        libtask-weaken-perl
        libterm-readkey-perl
        libtest-exception-perl
        libtest-longstring-perl
        libtest-mockobject-perl
        libtest-perl-critic-perl
        libtest-pod-coverage-perl
        libtest-pod-perl
        libtest-www-mechanize-perl
        libtext-charwidth-perl
        libtext-iconv-perl
        libtext-simpletable-perl
        libtext-wrapi18n-perl
        libtie-ixhash-perl
        libtime-clock-perl
        libtimedate-perl
        libtree-simple-perl
        libtree-simple-visitorfactory-perl
        libuniversal-can-perl
        libuniversal-isa-perl
        liburi-fetch-perl
        liburi-perl
        libuuid-perl
        libvariable-magic-perl
        libwww-mechanize-perl
        libwww-perl
        libxml-atom-perl
        libxml-dom-perl
        libxml-libxml-perl
        libxml-libxslt-perl
        libxml-namespacesupport-perl
        libxml-parser-perl
        libxml-perl
        libxml-regexp-perl
        libxml-sax-expat-perl
        libxml-sax-perl
        libxml-stream-perl
        libxml-twig-perl
        libxml-xpath-perl
        libxml-xslt-perl
        libyaml-perl
        libyaml-syck-perl
        libyaml-tiny-perl
        libfile-libmagic-perl
        liblog-log4perl-perl
        libplack-perl
        libcurses-perl
        libfile-libmagic-perl
        libnet-xmpp-perl
    '

    for pkg in $DEBPACKAGES; do
        echo ""
        echo "-- Installing $pgk"
        apt-get -y install $pkg
    done
}

function install_cent_perl_packages {

    # <rant> supporting cent sucks.  everything is so old that 
    # the net no longer knows how to fix there old crappy software.
    # we most likely just built a modern perl that won't work with
    # these old yum packages, so I'll try to install the cpanm versions

#    YUMPACKAGES='
#        perl
#        perl-devel
#        perl-CPAN
#        perl-Geo-IP
#        perl-Net-SSLeay
#    '
#
#    for pkg in $YUMPACKAGES; do
#        echo ""
#        echo "-- Installing $pgk"
#        yum install $pkg -y
#    done
#    local PPKGS='
#        CPAN
#        Net::SSLeay
#        LWP
#    '
#    for pkg in $PPKGS; do
#        echo ""
#        echo "-- using cpanm to install $pkg"
#        cpanm $pkg
#    done 
    echo "!!! are you sure you want to install on CentOS? Life is better on Ubuntu !!!"
    echo "-- installing things that should never be pulled out of a perl install, thanks centos"
    yum install perl-devel patch -y
    echo "-- installing perlbrew to get around crappy centos perl version"
    export PERLBREW_ROOT=/opt/perl5
    curl --insecure -L https://install.perlbrew.pl | bash
    echo "-- adding perlbrew environment to system profile"
    echo "source $PERLBREW_ROOT/etc/bashrc" > /etc/profile.d/perlbrew.sh
    source $PERLBREW_ROOT/etc/bashrc
    #echo "-- installing patchperl"
    #perlbrew install-patchperl
    echo "-- brewing 5.18.2"
    perlbrew install perl-5.18.2
    perlbrew switch perl-5.18.2

    echo "- PERL VERSION IS NOW -"
    perl -V
    local PVER=`perl -e 'print $];'`
    local PTAR="5.018"
    local COMP=`echo $PVER'>'$PTAR | bc -l`
    if [[ $COMP != 1 ]]; then
        echo "failed to upgrade perl, manual intervention required"
        exit 1;
    fi

    

}

function install_cpanm {
    
    echo "--"
    echo "-- refreshing cpanm"
    echo "--"

    if hash cpanm 2>/dev/null; then
        echo "-- using existing cpanm to refresh"
        cpanm App::cpanminus
    else
        echo "-- downloading cpanm"
        curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    fi
}

function perl_version_check {

    local PVER=`perl -e 'print $];'`
    local PTAR="5.018"
    local COMP=`echo $PVER'>'$PTAR | bc -l`

    echo "PERL reports version as $PVER"
    echo "want $PTAR or greater"
    echo "COMP is $COMP"

    if [[ $COMP == 1 ]];then
        echo "Yea! A modern perl! "
    else 
        echo "Your Perl is out of date.  Upgrade to 5.18 or better "
        echo "== See installation docs in docs/source/install.rst for instructions on how to install new perl"
        echo ""
        echo " this means yo uare most likely on a CentOS system, condolences."
        echo " the install script will attempt to install a working perl for you"
    fi
}


function install_packages {

    echo "---"
    echo "--- Installing System Perl Packages"
    echo "---"

    if [[ $OS == "Ubuntu" ]]; then
        install_ubuntu_packages
    else 
        # echo "-- cent packages suck.  allowing cpanm to build all dependencies"
        install_cent_perl_packages 
    fi
}

function install_perl_modules {

    if [[ $OS != "Ubuntu" ]]; then 
        echo "-- Cent/RH system, invoking perlbrew to modernize the perl"
        perlbrew switch perl-5.18.2
    fi

    PERLMODULES='
        Array::Split
        Data::Dumper
        Data::Dumper::HTML
        Data::Dumper::Concise
        Data::Clean@0.48
        Data::Clean::FromJSON
        Daemon::Control
        Net::LDAP
        Net::SMTP::TLS
        Net::Stomp
        Net::STOMP::Client
        Net::IDN::Encode
        Net::Works::Network
        Net::IP
        Moose
        Moose::Role
        Moose::Util::TypeConstraints
        MooseX::MetaDescription::Meta::Attribute
        MooseX::Singleton
        MooseX::Emulate::Class::Accessor::Fast
        MooseX::Types
        MooseX::Types::Common
        MooseX::MethodAttributes
        MooseX::Role::MongoDB@0.010
        Safe
        Readonly
        DateTime
        DateTime::Cron::Simple
        DateTime::Format::Strptime
        DateTime::Format::Natural
        Time::HiRes
        Server::Starter
        PSGI
        CGI::PSGI
        CGI::Compile
        HTTP::Server::Simple::PSGI
        JSON
        JSON::XS
        DBI
        Parallel::ForkManager
        AnyEvent
        AnyEvent::STOMP::Client
        AnyEvent::ForkManager
        Async::Interrupt
        Number::Bytes::Human
        Sys::RunAlone
        Encode
        FileHandle
        File::Slurp
        File::Temp
        File::Type
        HTML::Entities
        HTML::Scrubber
        HTML::Strip
        HTML::StripTags
        HTML::TreeBuilder
        HTML::FromText
        HTML::FormatText
        MIME::Base64
        IPC::Run
        IO::Prompt
        Log::Log4perl
        Mail::IMAPClient
        Mail::IMAPClient::BodyStructure
        MongoDB@1.8.3
        MongoDB::GridFS@1.8.3
        MongoDB::GridFS::File@1.8.3
        MongoDB::OID@1.8.3
        Meerkat
        Mojo
        MojoX::Log::Log4perl
        Mojolicious::Plugin::WithCSRFProtection
        Mojolicious::Plugin::TagHelpers
        XML::Smart
        Config::Auto
        Data::GUID
        File::LibMagic
        List::Uniq
        Domain::PublicSuffix
        Mozilla::PublicSuffix
        Crypt::PBKDF2
        Config::Crontab
        Test::JSON
        Math::Int128
        GeoIP2
        MaxMind::DB::Reader::XS
        Search::Elasticsearch
        Term::ANSIColor
        Courriel
        Statistics::Descriptive
        Net::SSH::Perl
        Net::SFTP
        Lingua::Stem
        Lingua::EN::StopWords
        XML::Twig
        XML::Simple
        SVG::Sparkline
    '

    # install_cpanm

    # test has probles with proxy and ssl 
    # -n skips the test and installs anyway.  
    # should not be a problem (until it is)
    cpanm -n LWP::Protocol::https

    for module in $PERLMODULES; do

        echo "--"
        echo "-- 1st attempt at installing $module"
        echo "--"

        cpanm $module

        if [[ $? == 1 ]]; then
            echo "!!!"
            echo "!!! $module failed install!  Will re-attempt later..."
            echo "!!!"
            RETRY="$RETRY $module"
        else
            echo "-- installed $module"
            echo "--"
        fi
    done

    for module in $RETRY; do
        echo "--"
        echo "-- 2nd attept to install $module"
        echo "--"
        cpanm $module

        if [[ $? == 1 ]]; then
            echo "!!! !!!"
            echo "!!! !!! final attempt to install $module failed!"
            echo "!!! !!! user intervention will be required"
            echo "!!! !!!"
            FAILED="$FAILED $module"
        fi
    done

    if [[ "$FAILED" != "" ]]; then
        echo "================ FAILED PERL MODULES ================="
        echo "The following list of modules failed to install.  "
        echo "Unfortunately they are necessary for SCOT to work."
        echo "Try installing them by hand: \"sudo -E cpanm module_name\""
        echo "Google any error messages or contact scot-dev@sandia.gov"
        for module in $FAILED; do
            if [[ $module == "AnyEvent::ForkManager" ]]; then
                echo "- forcing the install of AnyEvent::ForkManager"
                cpanm -f AnyEvent::ForkManager
            else 
                echo "    => $module"
            fi
        done
    fi
    
}

function install_perl {
    echo "---"
    echo "--- Installing Required Perl Packages and Modules"
    echo "---"
    perl_version_check
    install_packages
    install_cpanm
    install_perl_modules
}
