package Scot::Util::MongoFactory;

use Meerkat;
use Data::Dumper;

# not to self tomorrow:  adapt this to the new config style 

use Moose;
extends qw(Scot::Util);


has db_name => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1, 
    builder     => '_build_db_name',
);

sub _build_db_name {
    my $self    = shift;
    my $attr    = "db_name";
    my $default = "scot-prod";
    return $self->get_config_value($attr,$default);
}

has host    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1, 
    builder     => '_build_host',
);

sub _build_host {
    my $self    = shift;
    my $attr    = "host";
    my $default = "mongodb://localhost";
    return $self->get_config_value($attr,$default);
}
    
has write_safety => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1, 
    builder     => '_build_write_safety',
);

sub _build_write_safety {
    my $self    = shift;
    my $attr    = "write_safety";
    my $default = 1;
    return $self->get_config_value($attr,$default);
}

has find_master    => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1, 
    builder     => '_build_find_master',
);

sub _build_find_master {
    my $self    = shift;
    my $attr    = "find_master";
    my $default = 1;
    return $self->get_config_value($attr,$default);
}
    
# this is a factory object, returns a Meerkat, not a Scot::Util::Mongo
# Env.pm detects Factory in the package name and looks for get_{attr_name}
sub get_mongo {
    my $self    = shift;
    my $meerkat = Meerkat->new(
        model_namespace         => 'Scot::Model',
        collection_namespace    => 'Scot::Collection',
        database_name           => $self->db_name,
        client_options          => {
            host        => $self->host,
            w           => $self->write_safety,
            find_master => $self->find_master,
            socket_timeout_ms => 600000,
        },
    );

    return $meerkat;
}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    predicate   => 'has_log',
);

1;
