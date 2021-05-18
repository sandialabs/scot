#!/bin/bash


function install_cpanm {
    
    echo "--"
    echo "-- installing cpanm"
    echo "--"
    CPANMFILE=$DEVDIR/pkgs/cpanm
    cat $CPANMFILE | plenv exec perl - --sudo App::cpanminus
    plenv rehash

}


function install_packages {

    echo "---"
    echo "--- Installing System Perl Packages"
    echo "---"
    plenv exec carton install --cached

}

function bootstrap_carton {
    echo "---"
    echo "--- bootstraping Carton"
    echo "---"
    (cd $DEVDIR/pkgs/carton-bootstrap;./bootstap)
    plenv rehash
}

function build_plenv {
    echo "---"
    echo "--- building local perl with plenv"
    echo "---"
    PLENV_DIR=$HOME/.plenv
    PLENV_TAR="plenv.tar.gz"
    PLENV_VERSIONS=$PLENV_DIR/versions
    PERL=perl-5.30.3
    PERL_BUILD_DIR=$DEVDIR/buildperl
    PERL_TAR=$PERL.tar.gz
    PERL_INSTALL_DIR=$PLENV_VERSIONS/$PERL

    if [[ ! -d $PLENV_DIR ]];then
        mkdir $PLENV_DIR
    fi
    if [[ ! -d $PLENV_VERSIONS ]];then
        mkdir $PLENV_VERSIONS
    fi
    if [[ ! -d $PERL_INSTALL_DIR ]];then
        mkdir $PERL_INSTALL_DIR
    fi
    if [[ ! -d $PERL_BUILD_DIR ]];then
        mkdir $PERL_BUILD_DIR
    fi

    tar xzf $PLENV_TAR -C $PLENV_DIR
    tar xzf $PERL_TAR -C $PERL_BUILD_DIR
    
    PWD=$(pwd)
    cd $PERLBUILD_DIR/$PERL
    ./Configure -des -Dprefix=$PERL_INSTALL_DIR
    make
    make test
    make install
    cd $PWD

    # for next login
    # PROFILE=$HOME/.bash_profile
    PROFILE=/etc/bashrc
    echo 'export PATH="$HOME/.plenv/bin:$PATH' >> $PROFILE
    echo 'eval "$(plenv init -)"' >> $PROFILE

    # for now
    export PATH=$HOME/.plenv/bin:$PATH
    eval "$(plenv init -)"
    plenv global perl-5.30.3
    plenv rehash

}

function install_perl {
    echo "---"
    echo "--- Installing Required Perl Packages and Modules"
    echo "---"
    build_plenv
    bootstrap_carton
    install_cpanm
    install_perl_modules
}
