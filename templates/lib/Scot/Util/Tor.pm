package Scot::Util::Tor;

use Moose;

# move this eventually to a database configuration item
has tor_url => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'http://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=10.10.10.1',
    predicate   => 'has_tor_url',
);

1;
