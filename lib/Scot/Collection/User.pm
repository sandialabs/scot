package Scot::Collection::User;

use lib '../../../lib';
use Crypt::PBKDF2;
use HTML::Entities;
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

override api_create => sub {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    $log->debug("in users api-create");
    
    my $request = $href->{request}->{json};

    if (! $env->is_admin($href->{user},$href->{groups})) {
        die "Only Admin Users can create new Users";
    };

    my $password    = delete $request->{password};
    unless ($password) {
        $log->warn("Empty Password!");
        $password = '';
    }

    $request->{fullname} = encode_entities($request->{fullname});
    $request->{username} = encode_entities($request->{username});

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
};


sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({username => /$frag/});
    my @records = map { { id => $_->{id}, key => $_->{username} } }
                  $cursor->all;
    return wantarray ? @records : \@records;
}

override api_list => sub {
    my $self    = shift;
    my $href    = shift;
    my $user    = shift;
    my $groups  = shift;

    my $match   = $self->build_match_ref($href->{request});

    my $cursor  = $self->find($match);
    my $total   = $self->count($match);

    unless ( $self->env->is_admin($user,$groups) ) {
        $cursor->fields({
            id          => 1,
            username    => 1,
        });
    }

    my $limit = $self->build_limit($href);
    if ( defined $limit ) {
        $cursor->limit($limit);
    }
    else {
        $cursor->limit(50);
    }

    if ( my $sort   = $self->build_sort($href)) {
        $cursor->sort($sort);
    }
    else {
        $cursor->sort({id => -1});
    }

    if ( my $offset = $self->build_offset($href) ) {
        $cursor->skip($offset);
    }

    return ($cursor, $total);
};

1;
