package Scot::Collection::Entitytype;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
use Lingua::EN::StopWords qw(%StopWords);
use Try::Tiny;
extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
    Scot::Role::GetTargeted
);

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $json    = $request->{request}->{json};
    my $value   = lc($json->{value});
    my $opts    = delete $json->{options};
    my $match   = $json->{match};
    my $multi   = $opts->{multiword};

    if ( $match =~ / / ) {
        $log->debug("user defined entitytype has a space, setting multiword = yes");
        $multi  = "yes";
    }

    $value =~ s/ /-/g; # replace spaces in value

    my $et_obj  = $self->find_one({match => $match});

    unless (defined $et_obj) {
        $json->{value} = $value;
        $json->{options} = {
            multiword   => $multi
        };
        if ( $self->sane_match($json->{match})) {
            $log->debug("creating entitytype with ",{filter=>\&Dumper, value=>$json});
            $et_obj = $self->create($json);
        }
        else {
            $log->error("Insane user defined flair attempted. ".$json->{match});
            die "Unsupported user defined flair attempt";
        }
        # TODO: add history?
    }
    return $et_obj;
};

sub sane_match {
    my $self    = shift;
    my $match   = shift;

    if ( $match eq " " ) {
        return undef;
    }

    if ( defined $StopWords{$match} ) {
        return undef;    
    }

    # i'm sure our users will help educate us on further 
    # sets of words to disallow!

    return 1;
}

sub entity_type_exists {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $obj     = $self->find_one({ value => $value, type => $type });

    if ( defined $obj ) {
        return 1;
    }
    return undef;
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    if ( $subthing eq "entity" ) {
        my $et  = $self->find_one({id => $id});
        return $mongo->collection('Entity')->find({type => $et->value});
    }

    die "Unsupported subthing request ($subthing) for Entity";

}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $log     = $self->env->log;
    my @records = ();

    my $mm = quotemeta($frag);
    try {
        my $re      = qr/$mm/i;
        my $cursor  = $self->find({
            value => $re,
        });
        if ( defined $cursor ) {
            @records = map { {
                $_->{value}
            } } $cursor->all;
            push @records, $self->matching_predef($frag);
        }
    }
    catch {
        $log->error("Autocomplete failed: $_ ");
    };

    return wantarray ? @records : \@records;
}

sub matching_predef {
    my $self    = shift;
    my $frag    = shift;

    # hard coded for now, move to scot.cfg.pl later
    my @predef  = (qw(
        ipaddr
        cve
        md5
        sha1
        sha256
        ipv6
        domain
        email
        attack-pattern
        campain
        course-of-action
        identity
        indicator
        intrusion-set
        malware
        observed-data
        report
        threat-actor
        tool
        vulnerability
    ));
    my @records = grep { /$frag/i } @predef;
    return wantarray ? @records : \@records;
}


1;
