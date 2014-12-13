FROM ubuntu:latest
MAINTAINER Josh Maine, jmaine@sandia.gov

# Prevent daemon start during install
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

# Set proxy settings (if your environment requires it)
#ENV http_proxy http://PROXY_SERVER_HERE:80
#ENV https_proxy http://PROXY_SERVER_HERE:80

# Install `gosu` for easy step-down from root
USER root
RUN apt-get -qq update && apt-get install -yq curl \
  && curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
  && chmod +x /usr/local/bin/gosu \
  && apt-get purge -y --auto-remove curl \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install SCOT Dependancies
RUN buildDeps='gcc git-core make'; \
  apt-get -q update && \
  apt-get install -yq $buildDeps libapache2-mod-authnz-external dialog libcurses-perl libmagic-dev libxml-perl libyaml-perl perlmagick perltidy perl-doc groff libwww-mechanize-perl libjson-perl librose-db-perl libtree-simple-perl libtask-weaken-perl libtree-simple-visitorfactory-perl libalgorithm-c3-perl libapparmor-perl libarchive-zip-perl libauthen-krb5-simple-perl libauthen-sasl-perl libb-hooks-endofscope-perl libb-keywords-perl libbit-vector-perl libcache-perl libcairo-perl libcarp-assert-more-perl libcarp-assert-perl libcarp-clan-perl libcgi-simple-perl libclass-accessor-perl libclass-c3-adopt-next-perl libclass-c3-perl libclass-c3-xs-perl libclass-data-inheritable-perl libclass-errorhandler-perl libclass-factory-util-perl libclass-inspector-perl  libclass-singleton-perl libclone-perl libclone-pp-perl libcompress-bzip2-perl libconfig-tiny-perl libdata-dump-perl libdata-optlist-perl libdate-manip-perl libdatetime-format-builder-perl libdatetime-format-mysql-perl libdatetime-format-pg-perl libdatetime-format-strptime-perl libdatetime-locale-perl libdatetime-perl libdatetime-timezone-perl libdbd-mysql-perl libdbd-pg-perl libdbi-perl libdevel-globaldestruction-perl libdevel-stacktrace-perl libdevel-symdump-perl  liberror-perl libexception-class-perl libextutils-autoinstall-perl  libfcgi-perl libfile-copy-recursive-perl libfile-homedir-perl libfile-modified-perl libfile-nfslock-perl libfile-remove-perl libfile-searchpath-perl libfile-slurp-perl libfile-spec-perl libfile-which-perl libfont-afm-perl libfreezethaw-perl libglib-perl libgnome2-canvas-perl libgnome2-perl libgnome2-vfs-perl libgtk2-perl libheap-perl libhtml-clean-perl libhtml-format-perl libhtml-parser-perl libhtml-tagset-perl libhtml-template-perl libhtml-tree-perl libhttp-body-perl libhttp-request-ascgi-perl libhttp-response-encoding-perl libhttp-server-simple-perl libio-socket-ssl-perl libio-string-perl libio-stringy-perl libjson-perl libjson-xs-perl liblingua-stem-snowball-perl liblist-moreutils-perl liblocale-gettext-perl liblwp-authen-wsse-perl libmailtools-perl libmime-types-perl libmldbm-perl libmodule-corelist-perl libmodule-install-perl libmodule-scandeps-perl libmoose-perl libmoosex-emulate-class-accessor-fast-perl libmoosex-methodattributes-perl libmoosex-types-perl libmro-compat-perl libnamespace-autoclean-perl libnamespace-clean-perl libnet-daemon-perl libnet-dbus-perl libnet-jabber-perl libnet-libidn-perl libnet-ssleay-perl libnet-xmpp-perl libpango-perl libpar-dist-perl libparams-util-perl libparams-validate-perl libparse-cpan-meta-perl libparse-debianchangelog-perl libpath-class-perl libperl-critic-perl libplrpc-perl libpod-coverage-perl libpod-spell-perl libppi-perl libreadonly-perl libreadonly-xs-perl librose-datetime-perl librose-db-object-perl librose-db-perl librose-object-perl librpc-xml-perl libscope-guard-perl libscope-upper-perl libsphinx-search-perl libsql-reservedwords-perl libstring-format-perl libstring-rewriteprefix-perl libsub-exporter-perl libsub-install-perl libsub-name-perl libsub-uplevel-perl libtask-weaken-perl libterm-readkey-perl libtest-exception-perl libtest-longstring-perl libtest-mockobject-perl libtest-perl-critic-perl libtest-pod-coverage-perl libtest-pod-perl libtest-www-mechanize-perl libtext-charwidth-perl libtext-iconv-perl libtext-simpletable-perl libtext-wrapi18n-perl libtie-ixhash-perl libtime-clock-perl libtimedate-perl libtree-simple-perl libtree-simple-visitorfactory-perl libuniversal-can-perl libuniversal-isa-perl liburi-fetch-perl liburi-perl libuuid-perl libvariable-magic-perl libwww-mechanize-perl libwww-perl libxml-atom-perl libxml-dom-perl libxml-libxml-perl libxml-libxslt-perl libxml-namespacesupport-perl libxml-parser-perl libxml-perl libxml-regexp-perl libxml-sax-expat-perl libxml-sax-perl libxml-stream-perl libxml-twig-perl libxml-xpath-perl libxml-xslt-perl libyaml-perl libyaml-syck-perl libyaml-tiny-perl perl perl-base perl-doc perl-modules perlmagick perltidy libgssapi-krb5-2 libkrb5support0 libkrb5-3 krb5-doc lynx curl git-core java-common apache2 libapache2-mod-proxy-html libapache2-mod-rpaf libimlib2-dev libimlib2 starman libgeoip-dev default-jre libplack-perl cpanminus libio-prompt-perl  --no-install-recommends && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -r nonroot -g 433 \
  && useradd -u 431 -r -g nonroot -d /home/nonroot -s /sbin/nologin -c "Nonroot User" nonroot \
  && mkdir /home/nonroot \
  && chown -R nonroot:nonroot /home/nonroot

# Install Perl Modules
ADD install_perl_mods.sh /home/nonroot/
RUN chmod 755 /home/nonroot/install_perl_mods.sh
RUN chown -R nonroot:nonroot /home/nonroot
USER nonroot
WORKDIR /home/nonroot
RUN \
  ./install_perl_mods.sh && \
  apt-get purge -y --auto-remove gcc git-core make
