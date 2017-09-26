my @entries = (
    {
        owner   => "sydney",
        groups  => [
            read    => [ "bruner", "rios" ],
            modify  => [ "bruner" ],
        ],
        target  => {
            id      => 1,
            type    => "event",
        },
        body_plain  => "the quick brown fox jumped over the lazy dog",
        # updated   =>  filled in at creation time
        # created       ...
        # when          ...
        parent      => 0,
        parsed      => 1,
        summary     => 0,
        task        => {},
        is_task     => 0,
    },
);
