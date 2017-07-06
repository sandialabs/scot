package Scot::Collection::User;

use lib '../../../lib';
use Crypt::PBKDF2;

use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    
    my $request = $href->{request}->{json};

    my $password    = delete $request->{password};
    unless ($password) {
        $log->warn("Empty Password!");
        $password = '';
    }

    my $pbkdf2  = Crypt::PBKDF2->new(
        hash_class  => 'HMACSHA2',
        hash_args   => { sha_size => 512 },
        iterations  => 10000,
        salt_len    => 15,
    );
    my $hash        = $pbkdf2->generate($password);
    $request->{pwhash} = $hash;

    my $user    = $self->create($request);

    unless ($user) {
        $log->error("Failed to create user with data ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    return $user;
}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({username => /$frag/});
    my @records = map { { id => $_->{id}, key => $_->{username} } }
                  $cursor->all;
    return wantarray ? @records : \@records;
}

1;
