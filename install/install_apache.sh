#!/bin/bash

function install_apache {

    echo "---"
    echo "--- Installing Apache2 "
    echo "---"

    if [[ $OS == "Ubuntu" ]]; then
        echo "--"
        echo "-- Ubuntu based system install of apache2"
        echo "--"
        APACHE_PKGS="apache2 libapache2-mod-authnz-external libapache2-mod-rpaf"
        apt-get install -y $APACHE_PKGS
        SitesAvailable="/etc/apache2/sites-available"
        SitesEnabled="/etc/apache2/sites-enabled"
    else
        echo "--"
        echo "-- CENT/RH based system install of apache2"
        echo "--"
        APACHE_PKGS="httpd mod_ssl"
        yum install $APACHE_PKGS -y
        ApacheConfd="/etc/httpd/conf.d"
        setsebool -P httpd_can_network_connect 1
        echo "-- adding firewalld command to allow web traffic"
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
    fi

    echo "--"
    echo "-- configuring apache2"
    echo "--"

    local CSD="$DEVDIR/install/src/apache2"
    local CSF="$PRIVATE_SCOT_MODULES/etc/scot-revproxy.conf"

    echo "-- DEVDIR is $DEVDIR"
    echo "-- CSD    is $CSD"

    echo "- looking for $CSF"
    if [[ ! -e $CSF ]]; then

        # CSF="$CSD/scot-revproxy-${OS}-${AUTHMODE}.conf"
        CSF="$CSD/scot-revproxy-${OS}.conf"
        echo "- looking for $CSF"

        if [[ ! -e $CSF ]]; then
            echo -e "${red} FAILED to FIND revproxy config! ${nc}"
            echo "Installation can not proceed until fixed!"
            exit 1;
        fi
    fi

    echo "-"
    echo "- Found Scot Reverse Proxy Config File:"
    echo "- $CSF"
    echo "- installing..."
    echo "-"
    SCOT_APACHE_CONFIG=$SitesAvailable/scot.conf

    if [[ $OS == "Ubuntu" ]]; then

        if [[ -e $SitesEnabled/000-default.conf ]]; then
            echo "- removing 000-default.conf file"
            rm -f $SitesEnabled/000-default.conf
        fi

        if [[ $REFRESHAPACHECONF == "YES" ]] || [[ ! -e $SitesEnabled/scot.conf ]]; then
            cp $CSF $SCOT_APACHE_CONFIG
            ln -s $SCOT_APACHE_CONFIG $SitesEnabled/scot.conf
        fi
    else 
       echo "- clearing existing configs from $ApacheConfd"
       for FILE in $ApacheConfd/*conf
       do   
            if [[ $FILE != "$ApacheConfd/scot.conf" ]]; then
                mv $FILE $FILE.bak
            else
                if [[ $REFRESHAPACHECONF == "YES" ]]; then
                    mv $FILE $FILE.bak
                fi
            fi
       done
       SCOT_APACHE_CONFIG=/etc/httpd/conf.d/scot.conf
       cp $CSF $SCOT_APACHE_CONFIG
    fi

    if [[ "$MYHOSTNAME" == "" ]]; then
        MYHOSTNAME=`hostname`
    fi
    
    echo "-"
    echo "- Modifying $SCOT_APACHE_CONFIG"
    echo "- document root = $SCOTROOT"
    sed -i 's=/scot/document/root='$SCOTROOT'/public=g' $SCOT_APACHE_CONFIG
    echo "- revproxy port = $SCOTPORT"
    sed -i 's=localport='$SCOTPORT'=g' $SCOT_APACHE_CONFIG
    echo "- hostname      = $MYHOSTNAME"
    sed -i 's=scot\.server\.tld='$MYHOSTNAME'=g' $SCOT_APACHE_CONFIG
    echo "-"

    echo "-- checking that sed worked"
    if grep "localhost:localport" $SCOT_APACHE_CONFIG; then
        echo "!!!! Oh no! sed failed to edit $SCOT_APACHE_CONFIG"
    else
        echo "looks ok"
    fi
        

    SSLDIR="/etc/apache2/ssl"

    if [[ ! -d $SSLDIR ]]; then
        mkdir -p $SSLDIR
    fi

    if [[ ! -e $SSLDIR/scot.key ]]; then
        echo "-"
        echo "- Generating temporary SSL certificates"
        echo "- Please replace these with real Certificates as soon as possible"
        echo "-"
        openssl genrsa 2048 > $SSLDIR/scot.key
        openssl req -new -key $SSLDIR/scot.key \
                    -out /tmp/scot.csr \
                    -subj '/CN=localhost/O=SCOT Default Cert/C=US'
        openssl x509 -req -days 36530 \
                     -in /tmp/scot.csr \
                     -signkey $SSLDIR/scot.key \
                     -out $SSLDIR/scot.crt
    else
        echo "-"
        echo "- scot.key exists in $SSLDIR, "
        echo "-"
    fi

    if [[ $OS == "Ubuntu" ]]; then
        echo "- enabling modules in apache "
        AMODS="proxy proxy_http ssl headers rewrite authnz_ldap"
        for m in $AMODS
        do
            echo "+     enabling $m"
            a2enmod -q $m
        done
    else 
        echo "- CENT/RH Note"
        echo "-    this installer does not check that the contents of "
        echo "-    /etc/httpd/conf.modules.d are appropriate "
        echo "-    you will need to ensure that the proxy proxy_http ssl"
        echo "-    headers rewrite and authnz_ldap modules are enabled "
        echo "-    for scot to work."
    fi

    echo "-"
    echo "- apache install / config completed"
    echo "- apache still needs a restart "
    echo "-"
}

