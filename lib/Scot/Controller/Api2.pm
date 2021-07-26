package Scot::Controller::Api2;

use strict;
use warnings;
use utf8;
use Try::Tiny;
use Carp qw(longmess);
use Module::Runtime qw(require_module compose_module_name);

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub create ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->create($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Create Error: $_");
    };
}

sub list ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->list($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API List Error: $_");
    };
}

sub get_one ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->get_one($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Get_One Error: $_");
    };
}

sub get_related ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->get_related($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Get_Related Error: $_");
    };
}

sub update ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->update($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Update Error: $_");
    };

}

sub delete ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->delete($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API List Error: $_");
    };
}

sub undelete ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->undelete($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Undelete Error: $_");
    };
}

sub promote ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->promote($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Promote Error: $_");
    };

}

sub unpromote ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->unpromote($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Promote Error: $_");
    };
}

sub link ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->link($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Link Error: $_");
    };
}

sub maxid ($self) {
    my $request     = $self->get_api_request;
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
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->move($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Move Error: $_");
    };
}

sub wall ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->wall($request);
        $self->perform_render($result);
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
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->status($request);
        $self->perform_render($result);
    }
    catch {
        $self->render_error(400, "API Status Error: $_");
    };
}

sub export ($self) {
    my $log = $self->env->log;
    try {
        my $request = $self->get_api_request;
        my $domain  = $self->get_domain($request);
        my $result  = $domain->export($request);
        $self->perform_render($result);
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
    my $collection  = $request->{collection};
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
        status  => $result->{code},
        json    => $result->{json},
    );

}

1;
