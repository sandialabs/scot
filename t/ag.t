use lib '../lib';
use Scot::Env;
use Data::Dumper;

$env = Scot::Env->new();

$mongo = $env->mongo;

my $c = $mongo->collection('Alertgroup');
my $cursor = $c->find({});

while (my $ag = $cursor->next ) {
    print $ag->id."\n";
}
