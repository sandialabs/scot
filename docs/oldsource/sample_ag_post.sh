curl -XPOST username:password@localhost/scot/api/v2/alertgroup -d '
{
    message_id: '112233445566778899aabbccddeeff',
    subject: 'test message alert',
    data: [
        { column1: "data11", column2: "data21", column3: "data31" },
        { column1: "data12", column2: "data22", column3: "data32" },
        { column1: "data13", column2: "data23", column3: "data33" },
    ],
    tag: [ 'tag1', 'tag2', 'tag3' ],
    source: [ 'detector1' ],
    columns: [ 'column1', 'column2', 'column3' ],
}'
