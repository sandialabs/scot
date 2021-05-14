package Scot::Controller::Api2;

use strict;
use warnings;
use utf8;
use Try::Tiny;
use Carp qw(longmess);

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

}

sub get_domain ($self, $request) {

}

sub perform_render ($self, $result) {

}

1;
