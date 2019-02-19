package Scot::Collection::Entry;

use lib '../../../lib';
use Moose 2;
use Data::Dumper;
use HTML::Element;
use JSON::XS;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetTargeted
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_promoted_alert {
    my $self    = shift;
    my $alert   = shift;
    my $event   = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $mq      = $env->mq;
    my $json;

    $log->debug("Creating/Adding to Alert Entry from promoted Alert");

    $json->{groups}->{read}    = $alert->groups->{read} // 
                                 $env->default_groups->{read};
    $json->{groups}->{modify}  = $alert->groups->{modify} // 
                                 $env->default_groups->{modify};
    $json->{target}            = {
        type                  => 'event',
        id                    => $event->id,
    };
    my $id      = $alert->id;
    my $agcol   = $mongo->collection('Alertgroup');
    my $agobj   = $agcol->find_iid($alert->alertgroup+0);
    my $subject = $agobj->subject;
    $json->{body}              = 
        qq|<h3>From Alert <a href="/#/alert/$id">$id</a></h3><br>|.
        qq|<h4>|.$subject.qq|</h4>|.
        $self->build_table($alert);
    $log->trace("Using : ",{filter=>\&Dumper, value => $json});

    my $existing_entry = $self->find_existing_alert_entry("event", $event->id);

    if ( $existing_entry ) {
        # use this as the parent so that all additional alert promoted to this event
        # will be "enclosed" in on "alert" class entry.
        $json->{parent} = $existing_entry->id;
    }
    else {
        # create the "alert" type entry
        $log->debug("creating a new alert type entry");
        my $aentry  = $self->create({
            class   => "alert",
            parent  => 0,
            target  => {
                type    => 'event',
                id      => $event->id,
            },
        });
        $json->{parent} = $aentry->id;
    }

    #XXX

    $log->debug("creating the promoted alert entry");
    my $ahash   = $alert->as_hash;
    $log->trace("alert hash is ",{filter=>\&Dumper, value=>$ahash});
    $json->{metadata}          = { alert => $ahash };
    my $entry_obj              = $self->create($json);

    $log->debug("Created Entry : ".$entry_obj->id);
    return $entry_obj;
}

sub find_existing_alert_entry {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;

    my $col     = $self->env->mongo->collection('Entry');
    my $obj     = $col->find_one({
        'target.type'   => $type,
        'target.id'     => $id,
        class           => "alert",
    });

    if ( defined $obj and ref($obj) eq "Scot::Model::Entry" ) {
        $log->debug("Found an existing alert entry type for $type $id");
        return $obj;
    }
    $log->warn("Target of Alert promotion does not have an existing alert entry");
    return undef;
}

sub find_existing_file_entry {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
    my $col     = $self->env->mongo->collection('Entry');
    my $obj     = $col->find_one({
        'target.type'   => $type,
        'target.id'     => $id,
        class           => 'file',
    });
    if ( defined $obj and ref($obj) eq "Scot::Model::Entry" ) {
        $log->debug("found an existing file entry type for $type $id");
        return $obj;
    }
    $log->warn("Target of File upload does not have an existing file entry");
    return undef;
}


sub build_table {
    my $self    = shift;
    my $alert   = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $data    = $alert->data;
    my $html    = qq|<table class="tablesorter alertTableHorizontal">\n|;

    $log->debug("BUILDING ALERT TABLE");
    my $alerthref = $alert->as_hash;
    $log->debug({filter=>\&Dumper, value=>$alerthref});

    # some confusion as to where columns should actually be
    my $columns = $alert->columns;
    $log->debug("columns are ",{filter=>\&Dumper, value => $columns});

    if ( ! defined $columns or scalar(@$columns) == 0) { 
        $log->debug("Columns not in the right place!");
        $columns    = $data->{columns};
        $log->debug("columns are ",{filter=>\&Dumper, value => $columns});
    }
    else {
        $log->debug("columns ok? ",{filter=>\&Dumper, value => $columns});
    }

    if  ( ! defined $columns or scalar(@$columns) == 0) {
        $log->debug("Columns still unset!");
    }
    else {
        $log->debug("columns ok? ",{filter=>\&Dumper, value => $columns});
    }

    $html .= "<tr>\n";
    foreach my $key ( @{$columns} ) {
        next if ($key eq "columns");
        $html .= "<th>$key</th>";
    }
    $html .= "\n</tr>\n<tr>\n";
    
    # issue #446 states that special columns like message_id, etc. 
    # are flairing as email instead of message_id.  This is because
    # the flair engine handles alert data specially, looking at 
    # column headers.  Here is not quite the right place to do something
    # similar, though.  446 will have to remain open until we rework
    # the flair engine to handle this case better.  One idea is to 
    # wrap these items in special spans with flair "hints"  that the 
    # flair engine will recognize.  This will be similar to the approach
    # I'm thinking of using for user defined flair.

    foreach my $key ( @{$columns} ) {
        next if ($key eq "columns");
        my $value   = $data->{$key};
        if ( $key =~ /^message[_-]id$/i ) {
            $value =~ s{<(.*?)>}{&lt;$1&gt;};
        }

        $html .= qq|<td>|;
        if ( ref($value) eq "ARRAY" ) {
#            $html .= join("<br>\n",@$value)."</td>";
            $html .= join("\n",map { "    <div>$_</div>" } @$value)."</td>";
        }
        else {
            $html .= $value . "</td>";
        }
    }
    $html .= qq|\n</tr>\n</table>\n|;
    return $html;
}

sub create_from_file_upload {
    my $self        = shift;
    my $fileobj     = shift;
    my $entry_id    = shift;
    my $target_type = shift;
    my $target_id   = shift;
    my $fid         = $fileobj->id;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;
    my $htmlsrc     = <<EOF;
<div class="fileinfo">
    <table>
        <tr>
            <th align="left">File Id</th> <td>%d</td>
        </tr><tr>
            <th align="left">Filename</th><td>%s</td>
        </tr><tr>
            <th align="left">Size</th>    <td>%s</td>
        </tr><tr>
            <th align="left">md5</th>     <td>%s</td>
        </tr><tr>
            <th align="left">sha1</th>    <td>%s</td>
        </tr><tr>
            <th align="left">sha256</th>  <td>%s</td>
        </tr><tr>
            <th align="left">notes</th>   <td>%s</td>
        </tr>
    </table>
    <a href="/scot/api/v2/file/%d?download=1">
        Download
    </a>
</div>
EOF
    my $html = sprintf( $htmlsrc,
        $fileobj->id,
        $fileobj->filename,
        $fileobj->size,
        $fileobj->md5,
        $fileobj->sha1,
        $fileobj->sha256,
        $fileobj->notes,
        $fileobj->id);
    
    my $entry_href  = {
        parent     => $entry_id,
        body       => $html,
        target     => {
            id     => $target_id,
            type   => $target_type,
        },
        groups     => {
            read   => $fileobj->groups->{read} // $env->default_groups->{read},
            modify => $fileobj->groups->{modify} // $env->default_groups->{modify},
        },
    };

    $log->debug("creating file upload entry with ", {filter=>\&Dumper, value=>$entry_href});

    my $existing_entry = $self->find_existing_file_entry($target_type, $target_id);

    if ( $existing_entry ) {
        # use this as the parent so that all additional file uploads
        # will be "enclosed" in on "file" class entry.
        $entry_href->{parent} = $existing_entry->id;
    }
    else {
        # create the "alert" type entry
        $log->debug("creating a new file type entry");
        my $aentry  = $self->create({
            class   => "file",
            parent  => 0,
            target  => {
                type    => $target_type,
                id      => $target_id
            },
        });
        $entry_href->{parent} = $aentry->id;
    }

    my $entry_obj   = $self->create($entry_href);

    unless ( defined $entry_obj  and ref($entry_obj) eq "Scot::Model::Entry") {
        $log->error("Failed to create entry object!");
    }

    # TODO: need to actually update the updated time in the target

    return $entry_obj;

}

override api_create => sub {
    my $self    = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;
    my $user    = $req->{user};
    my $json    = $req->{request}->{json};
    my $target_type = $json->{target_type};
    my $target_id   = $json->{target_id};

    $log->debug("req is ",{filter=>\&Dumper, value=>$req});

    if ( ! defined $target_type or ! defined $target_id ) {
        die "Entries must have target_type and target_id defined";
    }

    if (my $task = $self->validate_task($req) ) {
        $json->{class}      = "task";
        $json->{metadata}   = { task => $task};
    }

    my $default_groups = $self->get_default_permissions($target_type, $target_id);
    $json->{groups}->{read} = 
        $default_groups->{read} if (!defined $req->{readgroups});
    $json->{groups}->{modify} = 
        $default_groups->{modify} if (!defined $req->{modifygroups});
    $json->{target} = {
        type    => $target_type,
        id      => $target_id,
    };
    $json->{owner}  = $user;
    if ( ! defined $json->{tlp} ) {
        $json->{tlp} = $self->get_target_tlp($target_type, $target_id);
    }
    if ( $json->{class} eq "json" ) {
        # we need to create body from json in metadata
        $json->{body}   = $self->create_json_html($json->{metadata});
    }
    return $self->create($json);
};

sub get_target_tlp {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $mongo   = $self->env->mongo;

    my $obj = $mongo->collection(ucfirst($type))->find_one({id => $id});
    if ( defined $obj) {
        if ( $obj->meta->does_role("Scot::Role::TLP") ) {
            # get targets tlp, if not defined set it to unset
            my $tlp = $obj->tlp // 'unset';
            $self->env->log->debug("Setting tlp to $tlp");
            return $tlp;
        }
    }
    return undef;
}


sub create_json_html {
    my $self    = shift;
    my $data    = shift;
    my $html    = '<pre>';
    $html       .= JSON::XS->new->utf8->pretty->allow_nonref->encode($data);
    $html       .= '</pre>';
    return $html;
}

sub create_json_html_as_elements {
    my $self    = shift;
    my $data    = shift;
    my $tree    = HTML::Element->new('div',"class" => "json-container");
    my $ul      = HTML::Element->new("ul", "class" => "json-container");
    $tree->push_content($ul);
    $self->build_tree($ul,$data);
    return $tree->as_HTML(undef, "    ", {});
}

sub build_scalar_element {
    my $self    = shift;
    my $data    = shift;
    my $element = HTML::Element->new("span", "class" => "string");
    $element->push_content('"'.$data.'"');
    return $element;
}

sub build_hash_element {
    my $self    = shift;
    my $data    = shift;
    my $element = HTML::Element->new("li");
    my $expand  = HTML::Element->new("span", "class" => "expanded");
    $element->push_content($expand);
    my $open    = HTML::Element->new("span", "class" => "open");
    $open->push_content('{');
    $element->push_content($open);
    my $ul      = HTML::Element->new("ul", "class" => "object");
    $element->push_content($ul);

    foreach my $key ( sort keys %$data ) {
        my $li  = HTML::Element->new("li");
        my $key2 = HTML::Element->new("span", "class" => "key");
        $key2->push_content('"'.$key.'": ');
        $li->push_content($key2);
        my $value   = $data->{$key};
        $self->build_tree($li, $value);
        $ul->push_content($li);
    }
    $element->push_content($ul);
    my $close   = HTML::Element->new("span", "class" => "close");
    $close->push_content('}');
    $element->push_content($close);
    return $element;
}

sub build_array_element {
    my $self    = shift;
    my $data    = shift;
    my $element = HTML::Element->new("li");
    my $expand  = HTML::Element->new("span", "class" => "expanded");
    $element->push_content($expand);
    my $open    = HTML::Element->new("span", "class" => "open");
    $open->push_content('[');
    $element->push_content($open);
    my $ul      = HTML::Element->new("ul", "class" => "object");
    $element->push_content($ul);

    foreach my $value (@$data ) {
        my $li  = HTML::Element->new("li");
        $self->build_tree($li,$value);
        $ul->push_content($li);
    }
    $element->push_content($ul);
    my $close   = HTML::Element->new("span", "class" => "close");
    $close->push_content(']');
    $element->push_content($close);
    return $element;
}





sub build_tree {
    my $self    = shift;
    my $stem    = shift;
    my $data    = shift;
    my $nodetype    = ref($data);
    my $element;

    if ( $nodetype eq '' ) {
        $element    = $self->build_scalar_element($data);
    }

    if ( $nodetype eq "ARRAY" ) {
        $element    = $self->build_array_element($data);
    }

    if ( $nodetype eq "HASH" ) {
        $element    = $self->build_hash_element($data);
    }

    $stem->push_content($element);
}

sub validate_task {
    my $self    = shift;
    my $href    = shift;
    my $json    = $href->{request}->{json};

    unless ( defined $json->{task} ) {
        # if task isn't set that is ok and valid
        return undef; 
    }

    # however, if it is set, we need to make sure it has 
    # { when => x, who => user, status => y }

    unless ( defined $json->{task}->{when} ) {
        $href->{when} = $self->env->now();
    }

    unless ( defined $json->{task}->{who} ) {
        $href->{who}    = $href->{user};
    }
    unless ( defined $json->{task}->{status} ) {
        $href->{status} = "open";
    }
    return $href;
}


sub get_entries {
    my $self    = shift;
    my %params  = @_;
    my $id      = $params{target_id};
    my $thing   = $params{target_type};
    $id         +=0;

    my $cursor  = $self->find({
        'target.type' => $thing,
        'target.id'   => $id,
    });
    return $cursor;
}

sub get_tasks   {
    my $self    = shift;
    my $cursor  = $self->find({
        'task.status'   => { '$exists' => 1}
    });
    return $cursor;
}

sub create_file_entry {
    my $self    = shift;
    my $fileobj = shift;
    my $entryid = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $entryid += 0;

    my $fid     = $fileobj->id;
    my $htmlsrc = <<EOF;

<div class="fileinfo">
    <table>
        <tr>
            <th>File Id</th>%d</td>
            <th>Filename</th><td>%s</td>
            <th>Size</th><td>%s</td>
            <th>md5</th><td>%s</td>
            <th>sha1</th><td>%s</td>
            <th>sha256</th><td>%s<d>
            <th>notes</th><td>%s</td>
    </table>
    <a href="/scot/file/%d?download=1">
        Download
    </a>
</div>
EOF
    my $html = sprintf(
        $htmlsrc,
        $fileobj->id,
        $fileobj->filename,
        $fileobj->size,
        $fileobj->md5,
        $fileobj->sha1,
        $fileobj->sha256,
        $fileobj->notes,
        $fileobj->id);

    my $newentry;
    my $parententry = $self->find_iid($entryid);

    # TODO: potential problem here that needs more thought
    #  groups is being set to default_groups and probably should inherit from parent
    # entry_id or target's permissions

    my $href    = {
        body    => $html,
        parent  => $entryid,
        groups  => $self->get_default_permissions($parententry->target->{type}, $parententry->target->{id}),
        target  => {
            type    => $parententry->target->{type},
            id      => $parententry->target->{id},
        },
    };

    $log->debug("Creating Entry with ", {filter=>\&Dumper, value => $href});

#    try {
        $newentry = $self->create($href);
#    }
#    catch {
#        $log->error("Failed to create Entry!: $_");
#    };

    return $newentry;
}

sub get_entries_on_alertgroups_alerts {
    my $self        = shift;
    my $alertgroup  = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;

    my $id  = $alertgroup->id;
    my $ac  = $mongo->collection('Alert')->find({alertgroup => $id});

    return undef unless ( $ac );

    my @aids = map { $_->{id} } $ac->all;

    my $cursor = $self->find({
        'target.id'   => { '$in' => \@aids },
        'target.type' => 'alert',
    });
    return $cursor;
}

sub api_subthing {
    my $self        = shift;
    my $req         = shift;
    my $thing       = $req->{collection};
    my $id          = $req->{id} + 0;
    my $subthing    = $req->{subthing};
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;

    $log->debug("getting /$thing/$id/$subthing");

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')
                    ->find({
                        'target.id'   => $id,
                        'target.type' => 'entry'
                    });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'entry' },
                        'entity' );
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    if ( $subthing eq "file" ) {
        return $mongo->collection('File')
                    ->find({entry => $id});
    }

    die "unsupported subthing $subthing!";
}

sub get_entries_by_target {
    my $self    = shift;
    my $target  = shift; # { id => , type =>  }
    my $cursor  = $self->find({
        'target.id' => $target->{id},
        'target.type'   => $target->{type},
    });
    return $cursor;
}

sub move_entry {
    my $self    = shift;
    my $object  = shift;
    my $thref   = shift;
    my $mongo   = $self->env->mongo;

    my $current = $mongo->collection(
        ucfirst($object->target->{type})
    )->find_iid($object->target->{id});

    my $new     = $mongo->collection(
        ucfirst($thref->{type})
    )->find_iid($thref->{id});

    $current->update({
        '$set'  => { updated => $self->env->now },
        '$inc'  => { entry_count => -1 },
    });
    $new->update({
        '$set'  => { updated => $self->env->now },
        '$inc'  => { entry_count => 1 },
    });
}

sub tasks_not_completed_count {
    my $self    = shift;
    my $obj     = shift; # the target
    my $type    = $obj->get_collection_name;
    my $id      = $obj->id;
    my $match   = {
        'target.type'   => $type,
        'target.id'     => $id,
        'class'         => "task",
        'metadata.task.status'   => { '$nin' => ['completed','closed'] }
    };

    #my $cursor  = $self->find($match);
    #return $cursor->count // 0;
    my $count   = $self->count($match);
    return $count // 0;
}

sub get_target_summary {
    my $self    = shift;
    my $obj     = shift;
    my $match   = {
        'target.type'   => $obj->get_collection_name,
        'target.id'     => $obj->id,
        'class'         => 'summary',
    };
    my $cursor  = $self->find($match);
    return $cursor;
}

1;
