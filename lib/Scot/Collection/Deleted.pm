package Scot::Collection::Deleted;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of Deleted from Web API not supported",
    };
}


1;
