package Scot::App::Tor;

use lib '../../../lib';

=head1 Name

Scot::App::Tor

=head1 Description

Go and check the TOR projects list of nodes
Add them as entities

=cut

use Data::Dumper;
use Try::Tiny;
use Scot::Env;
use LWP::Simple;
use LWP::Protocol::https;
use strict;
use warnings;

use Moose;

sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $config  = $self->config;

    $log->trace("Beginning Tor Node Processing...");

    my $url     = $env->tor_url;
    my $ua      = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0});

    $ua->proxy($config->proxy_protos, $config->proxy_url);
    my $response = $ua->get($url);
    my $content = $response->content;

    # process content and insert as entities into SCOt.

    my @lines       = grep !/^\x27/, split(/\n/, $content);

    $log->trace(scalar(@lines), " ipaddresses received from $url");

    my $entities    = $mongo->collection('Entity');
    my @ips         = ();

    IPADDR:
    foreach my $ipaddr (@lines) {
        push @ips, $ipaddr;
        my $entity  = $entities->find_one({
            type    => 'ipaddr',
            value   => $ipaddr,
        });
        if ( $entity ) {
            # add tor ness to entity info
            unless ( grep { /tor/ } @{$entity->classes} ) {
                my $cmd    = {
                    '$push' => {
                        history => {
                            when    => $env->now,
                            who     => 'Tor Project',
                            what    => 'ip address listed as exit node',
                        },
                    },
                    '$addToSet' => { classes => 'tor' },
                };
                unless ( $entity->update($cmd) ) {
                    $log->error("Failed to update entity ".$entity->id." ".
                                $entity->value." with torness");
                    next IPADDR;
                }
                $env->amq->send_amq_notification("update", $entity, "torbot");
            }
            else {
                $log->trace("$ipaddr is already in scot as a tor exit node");
            }
        }
        else {
            # create entity
            my $entity  = $entities->create({
                type    => 'ipaddr',
                value   => $ipaddr,
                '$addToSet' => { classes => 'tor' },
                '$push'     => { history => {
                        when    => $env->now,
                        who     => 'Tor Project',
                        what    => 'ip address listed as exit node',
                    },
                },
            });
            unless ($entity) {
                $log->error("Failed to create entity for $ipaddr Tor Exit node");
                next IPADDR;
            }
            $env->amq->send_amq_notification("create", $entity, "torbot");
        }
    }

    # remove tor from entities no long doing tor
    my $cursor  = $entities->find({
        type    => "ipaddr",
        value   => { '$nin' => \@ips },
        class   => 'tor',
    });

    REMOVER:
    while ( my $entity = $cursor->next ) {
        unless ( $entity->update({
            '$pullAll'  => { class  => 'tor' },
            '$push'     => { history => {
                    when    => $env->now,
                    who     => "Tor Project",
                    what    => "no longer lists this ip address as an exit node",
                }
            },
        }) ) {
            $log->error("Failed to remove Tor exit node class from entity ".$entity->value);
            next REMOVER;
        }
        $env->amq->send_amq_notification("update", $entity, "torbot");
    }
}

1;
