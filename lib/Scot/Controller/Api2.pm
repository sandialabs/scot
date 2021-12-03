package Scot::Controller::Api2;

use strict;
use warnings;
use utf8;
use Try::Tiny;
use Carp qw(longmess);
use Module::Runtime qw(require_module compose_module_name);
use Data::Dumper;

use Mojo::Base 'Mojolicious::Controller', -signatures;


sub create ($self) {
    my $log = $self->env->log;
    $log->info('-- CREATE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->create($request);
        my $return  = $domain->process_create_result($result, $request);
        $self->perform_render($return);
        $self->write_audit_record('create', $request, $result);
    }
    catch {
        $self->render_error(400, "API Create Error: $_");
    };
}

sub list ($self) {
    my $log = $self->env->log;
    $log->info('-- LIST -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->list($request);
        my $return  = $domain->process_list_results($result, $request);
        $self->perform_render($return);
        $self->write_audit_record('list', $request, $result);
    }
    catch {
        $self->render_error(400, "API List Error: $_");
    };
}

sub get_one ($self) {
    my $log = $self->env->log;
    $log->info('-- GET_ONE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->get_one($request);
        my $return  = $domain->process_get_one($request, $result);
        $self->perform_render($return);
        $self->write_audit_record('get_one', $request, $result);
    }
    catch {
        $self->render_error(400, "API Get_One Error: $_");
    };
}

sub get_related ($self) {
    my $log = $self->env->log;
    $log->info('-- GET_RELATED -----------------------');
    try {
        my $request = $self->get_request_obj;
        $log->debug("request = ",{filter=>\&Dumper, value=>$request->as_hash});
        my $domain  = $self->get_domain($request);
        my $result  = $domain->get_related($request);
        my $return  = $domain->process_get_related($result);
        $self->perform_render($return);
        $self->write_audit_record('get_related', $request, $result);
    }
    catch {
        $self->render_error(400, "API Get_Related Error: $_");
    };
}

sub update ($self) {
    my $log = $self->env->log;
    $log->info('-- UPDATE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->update($request);
        $self->perform_render($result);
        $self->write_audit_record('update', $request, $result);
    }
    catch {
        $self->render_error(400, "API Update Error: $_");
    };

}

sub delete ($self) {
    my $log = $self->env->log;
    $log->info('-- DELETE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->delete($request);
        $self->perform_render($result);
        $self->write_audit_record('delete', $request, $result);
    }
    catch {
        $self->render_error(400, "API List Error: $_");
    };
}

sub undelete ($self) {
    my $log = $self->env->log;
    $log->info('-- UNDELETE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->undelete($request);
        $self->perform_render($result);
        $self->write_audit_record('undelete', $request, $result);
    }
    catch {
        $self->render_error(400, "API Undelete Error: $_");
    };
}

sub promote ($self) {
    my $log = $self->env->log;
    $log->info('-- PROMOTE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->promote($request);
        $self->perform_render($result);
        $self->write_audit_record('promote', $request, $result);
    }
    catch {
        $self->render_error(400, "API Promote Error: $_");
    };

}

sub unpromote ($self) {
    my $log = $self->env->log;
    $log->info('-- UNPROMOTE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->unpromote($request);
        $self->perform_render($result);
        $self->write_audit_record('unpromote', $request, $result);
    }
    catch {
        $self->render_error(400, "API Promote Error: $_");
    };
}

sub link ($self) {
    my $log = $self->env->log;
    $log->info('-- LINK -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->link($request);
        $self->perform_render($result);
        $self->write_audit_record('link', $request, $result);
    }
    catch {
        $self->render_error(400, "API Link Error: $_");
    };
}

sub maxid ($self) {
    my $request     = $self->get_request_obj;
    my $domain      = $self->get_domain($request);
    my $collection  = lc($request->{subthing});
    my $maxid       = $domain->max_id;
    my $result      = {
        max_id      => $maxid,
        collection  => $collection,
    };
    $self->perform_render($result);
}

sub move ($self) {
    my $log = $self->env->log;
    $log->info('-- MOVE -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->move($request);
        $self->perform_render($result);
        $self->write_audit_record('move', $request, $result);
    }
    catch {
        $self->render_error(400, "API Move Error: $_");
    };
}

sub wall ($self) {
    my $log = $self->env->log;
    $log->info('-- WALL -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->wall($request);
        $self->perform_render($result);
        $self->write_audit_record('wall', $request, $result);
    }
    catch {
        $self->render_error(400, "API Wall Error: $_");
    };

}

sub whoami ($self) {
    return $self->status;
}

sub status ($self) {
    my $log = $self->env->log;
    $log->info('-- STATUS -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->status($request);
        $self->perform_render($result);
        $self->write_audit_record('status', $request, $result);
    }
    catch {
        $self->render_error(400, "API Status Error: $_");
    };
}

sub export ($self) {
    my $log = $self->env->log;
    $log->info('-- EXPORT -----------------------');
    try {
        my $request = $self->get_request_obj;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->export($request);
        $self->perform_render($result);
        $self->write_audit_record('export', $request, $result);
    }
    catch {
        $self->render_error(400, "API Status Error: $_");
    };
}

sub render_error ($self, $code, $errormsg) {
    my $log = $self->env->log;
    $log->error('--------------------');
    $log->error($errormsg);
    $log->error(longmess);
    $log->error('--------------------');
    $self->perform_render({
        error   => $errormsg,
        code    => $code,
    });
}

sub get_request_obj ($self) {
    my $class   = "Scot::Request::".ucfirst($self->stash('thing'));
    require_module($class);
    my $ro  = $class->new($self);
    return $ro;
}

sub get_api_request ($self) {
    my $env = $self->env;
    my $log = $env->log;

    $log->trace("get_api_request");

    my $mojo_request    = $self->req;
    my $params          = $mojo_request->params->to_hash;
    my $json            = $mojo_request->json;

    if ( defined $params ) {
        $params = $self->normalize_json_in_params($params);
    }

    my %scot_request    = (
        collection      => $self->stash('thing'),
        id              => $self->stash('id') + 0,
        subcollection   => $self->stash('subthing'),
        subid           => $self->stash('subid') + 0,
        user            => $self->session('user'),
        groups          => $self->session('groups'),
        data            => {
            params  => $params,
            json    => $json,
        },
    );

    return wantarray ? %scot_request : \%scot_request;
}

sub get_domain ($self, $request) {
    my $log         = $self->env->log;
    my $mongo       = $self->env->mongo;
    my $collection  = $request->collection;
    my $classname   = 'Scot::Domain::'.ucfirst(lc($collection));

    try {
        require_module($classname);
    }
    catch {
        $log->logdie("Failed Require of $classname: $_");
    };

    my $domain = try {
        $classname->new({log => $log, mongo => $mongo});
    }
    catch {
        $log->logdie("Instantiation of $classname failed: $_");
    };

    if ( defined $domain and ref($domain) eq $classname ) {
        return $domain;
    }
    $log->logdie("Can not work on collection $collection because unable to create domain instance of $classname");
}

sub perform_render ($self, $result) {

    $self->render(
        json    => $result->{json},
        status  => $result->{code},
    );

}
sub write_audit_record ($self, $type, $request, $result) {
    my $mongo   = $self->env->mongo;
    my $audit   = $mongo->collection('Audit');
    my $record  = {
        who     => $request->user,
        when    => time(),
        what    => $type,
        data    => {
            request => $request->as_hash,
            result  => $result,
        }
    };

    if ( $type eq "list" or $type eq "get_one" or $type eq "get_related" ) {
        delete $record->{data}->{result};
    }

    $audit->create($record);

}

1;
