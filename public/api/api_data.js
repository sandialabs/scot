define({ "api": [
  {
    "type": "post",
    "url": "/scot/api/v2/apikey",
    "title": "get an apikey",
    "name": "Apikey",
    "group": "Auth",
    "version": "2.0.0",
    "description": "<p>Create an apikey and return it to a user</p>",
    "filename": "./Scot.pm",
    "groupTitle": "Auth"
  },
  {
    "type": "post",
    "url": "/auth",
    "title": "Request Authentication",
    "name": "AuthenticateUser",
    "group": "Auth",
    "version": "2.0.0",
    "description": "<p>submit credentials for authentication This route is only works on Local and LDAP authentication.  RemoteUser authentication relies on the browser BasicAuth popup.</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user",
            "description": "<p>username of the person attempting to authenticate</p>"
          },
          {
            "group": "Parameter",
            "type": "string",
            "optional": false,
            "field": "pass",
            "description": "<p>password of the person attempting authentication</p>"
          }
        ]
      }
    },
    "success": {
      "fields": {
        "200": [
          {
            "group": "200",
            "type": "Cookie",
            "optional": false,
            "field": "Encrypted",
            "description": "<p>Session Cookie</p>"
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Auth"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/cidr/:cidrbase/:bits",
    "title": "get list of ip entities in cidr block",
    "name": "CIDR",
    "group": "CIDR",
    "version": "2.0.0",
    "description": "<p>get list of IP address entities in SCOT that match a CIDR block</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": "<p>List of IP addresses</p>"
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "CIDR"
  },
  {
    "type": "post",
    "url": "/scot/api/v2/:thing",
    "title": "Create thing",
    "name": "Create__thing",
    "group": "CRUD",
    "version": "2.0.0",
    "description": "<p>Create a :thing</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": "<p>The JSON of object to create</p>"
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "delete",
    "url": "/scot/api/v2/:thing/:id/:subthing/:subid",
    "title": "Break Link",
    "name": "Delete_a_thing_related_to_a_thing",
    "version": "2.0.0",
    "group": "CRUD",
    "description": "<p>Delete a linkage between a thing and a related subthing. For example, a tag &quot;foo&quot; may be applied to many events.  You wish to disassociate &quot;foo&quot; with event 123, but retain the tag &quot;foo&quot; for use with other events.</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The &quot;alert&quot;, &quot;event&quot;, &quot;incident&quot;, &quot;intel&quot;, etc. you wish to retrieve</p>"
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl -XDELETE https://scotserver/scot/api/v2/event/123/tag/11",
        "type": "json"
      }
    ],
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    id : 123,\n    thing: \"event\",\n    subthing: \"tag\",\n    subid: 11,\n    status : \"ok\",\n    action: \"delete\"\n}",
          "type": "json"
        }
      ]
    },
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "delete",
    "url": "/scot/api/v2/:thing/:id",
    "title": "Delete Record",
    "name": "Delete_thing",
    "version": "2.0.0",
    "group": "CRUD",
    "description": "<p>Delete thing</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The &quot;alert&quot;, &quot;event&quot;, &quot;incident&quot;, &quot;intel&quot;, etc. you wish to retrieve</p>"
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl -X DELETE https://scotserver/scot/api/v2/event/123",
        "type": "json"
      }
    ],
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    id : 123,\n    thing: \"event\",\n    status : \"ok\",\n    action: \"delete\"\n}",
          "type": "json"
        }
      ]
    },
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/:thing/:id",
    "title": "View Record",
    "name": "Display__thing__id",
    "version": "2.0.0",
    "group": "CRUD",
    "description": "<p>Display the :thing with matching :id</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The collection you are trying to access</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>The integer id of the :thing to display</p>"
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": "<p>The JSON representation of the thing</p>"
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    key1: value1,\n    ...\n}",
          "type": "json"
        }
      ]
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl https://scotserver/scot/api/v2/alert/123",
        "type": "json"
      }
    ],
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "post",
    "url": "/scot/api/v2/:thing/:id/:subthing",
    "title": "List Related Records",
    "name": "Get_related_information",
    "version": "2.0.0",
    "group": "CRUD",
    "description": "<p>Retrieve subthings related to the thing</p> <h2>Alertgroup subthings</h2> <ul> <li>alert</li> <li>entity</li> <li>entry</li> <li>tag</li> <li>source</li> </ul> <h2>Alert subthings</h2> <ul> <li>alertgroup</li> <li>entity</li> <li>entry</li> <li>tag</li> <li>source</li> </ul> <h2>Event subthings</h2> <ul> <li>entity</li> <li>entry</li> <li>tag</li> <li>source</li> </ul> <h2>Incident subthings</h2> <ul> <li>events</li> <li>entity</li> <li>entry</li> <li>tag</li> <li>source</li> </ul>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The &quot;alert&quot;, &quot;event&quot;, &quot;incident&quot;, &quot;intel&quot;, etc. you wish to retrieve</p>"
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl -XGET https://scotserver/scot/api/v2/event/123/entry",
        "type": "json"
      }
    ],
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    \"queryRecordCount\": 25,\n    \"totalRecordCount\": 102,\n    [\n        { key1: value1, ... },\n        ...\n    ]\n}",
          "type": "json"
        }
      ]
    },
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/:thing",
    "title": "List Records",
    "name": "List__thing",
    "group": "CRUD",
    "version": "2.0.0",
    "description": "<p>List set of :thing objects that match provided params The params passed to this route allow you to filter the list returned to you.</p> <ul> <li> <p>If the column_name is a string column, the value of the param is placed within a / / regex search</p> </li> <li> <p>If the column_name is tag or source, comma seperated strings can be sent and matching records will have to have ALL tags, or sources, listed.</p> </li> <li> <p>If the column_name is tag or source, pipe '|' seperated strings can be sent and matching records will have to have AT Least One tags, or sources, listed.</p> </li> <li> <p>If the column_name is a date field, the field assumes an array of values and will search for datetimes between the least value and the greatest value of the provided array</p> </li> <li> <p>If the column_name is a numeric column, the following can be can sent:</p> <table> <thead> <tr> <th>value</th> <th>Explanation</th> </tr> </thead> <tbody> <tr> <td>x</td> <td>value of column name must equal number x</td> </tr> <tr> <td>&gt;=x</td> <td>value of column name must be greater or equal to x</td> </tr> <tr> <td>&gt;x</td> <td>value of column name must be greater than x</td> </tr> <tr> <td>&lt;=x</td> <td>value of column name must be less than or equal to x</td> </tr> <tr> <td>&lt;x</td> <td>value of column name must be less than x</td> </tr> <tr> <td>&lt;x|&gt;y</td> <td>value of column name must be less than x or greater than y</td> </tr> <tr> <td>&gt;x|&lt;y</td> <td>value of column name must be less than y and greater than x</td> </tr> <tr> <td>=x|=y|=z</td> <td>value of column name must be equal to x or y or z</td> </tr> </tbody> </table> </li> </ul>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The collection you are trying to access</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "column_name_1",
            "description": "<p>condition, see above</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "column_name_x",
            "description": "<p>condition, see above</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "columns",
            "description": "<p>Array of Column Names to return</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "limit",
            "description": "<p>Return no more than this number of records</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "offset",
            "description": "<p>Start returned records after this number of records</p>"
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          },
          {
            "group": "Success 200",
            "type": "Number",
            "optional": false,
            "field": "-.queryRecordCount",
            "description": "<p>Number of Records Returned</p>"
          },
          {
            "group": "Success 200",
            "type": "Number",
            "optional": false,
            "field": "-.totalRecordCount",
            "description": "<p>Number of all Matching Records</p>"
          },
          {
            "group": "Success 200",
            "type": "Object[]",
            "optional": false,
            "field": "-.records",
            "description": "<p>Records of type requested</p>"
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    \"records\":  [\n        { key1: value1, ..., keyx: valuex },\n        ...\n    ],\n    \"queryRecordCount\": 25,\n    \"totalRecordCount\": 102323\n}",
          "type": "json"
        }
      ]
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl -XGET https://scotserver/scot/api/v2/alert",
        "type": "json"
      }
    ],
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "put",
    "url": "/scot/api/v2/:thing/:id",
    "title": "Update thing",
    "name": "Updated_thing",
    "version": "2.0.0",
    "group": "CRUD",
    "description": "<p>update thing</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "thing",
            "description": "<p>The &quot;alert&quot;, &quot;event&quot;, &quot;incident&quot;, &quot;intel&quot;, etc. you wish to retrieve</p>"
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example Usage",
        "content": "curl -XPUT https://scotserver/scot/api/v2/event/123 -d '{\"key1\": \"value1\", ...}'",
        "type": "json"
      }
    ],
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "HTTP/1.1 200 OK\n{\n    id : 123,\n    status : \"successfully updated\",\n}",
          "type": "json"
        }
      ]
    },
    "filename": "./Scot.pm",
    "groupTitle": "CRUD"
  },
  {
    "type": "post",
    "url": "/scot/api/v2/file",
    "title": "Upload File",
    "name": "File_Uploader",
    "group": "File",
    "version": "2.0.0",
    "description": "<p>Upload a file to the SCOT system</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": "<p>JSON of File Record.  set &quot;sendto&quot; attribute</p>"
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "File"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/game",
    "title": "SCOT Gamefication",
    "name": "game",
    "group": "Game",
    "version": "2.0.0",
    "description": "<p>provide fun? stats on analyst behavior</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Game"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/graph/:thing",
    "title": "",
    "name": "metric",
    "group": "Metric",
    "version": "2.0.0",
    "description": "<p>build a graph (nodes,vertices) starting at :thing :id and going out :depth connections</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Metric"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/who",
    "title": "",
    "name": "metric",
    "group": "Metric",
    "version": "2.0.0",
    "description": "<p>like the unix who command but for SCOT</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Metric"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/metric/:thing",
    "title": "Get a metric from SCOT",
    "name": "metric",
    "group": "Metric",
    "version": "2.0.0",
    "description": "<p>Get a metric from scot db</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Metric"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/status",
    "title": "",
    "name": "metric",
    "group": "Metric",
    "version": "2.0.0",
    "description": "<p>give the status of the scot system</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Metric"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/graph/:thing",
    "title": "",
    "name": "metric",
    "group": "Metric",
    "version": "2.0.0",
    "description": "<p>Get pyramid, dhheatmap, statistics, todaystats, bullet, or alertresponse data</p>",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Metric"
  },
  {
    "type": "put",
    "url": "/scot/api/v2/command/:action",
    "title": "Send Queue Command",
    "name": "send_command_to_queue",
    "group": "Queue",
    "version": "2.0.0",
    "description": "<p>send the the string :command to the scot activemq topic queue</p>",
    "filename": "./Scot.pm",
    "groupTitle": "Queue"
  },
  {
    "type": "put",
    "url": "/scot/api/v2/wall",
    "title": "Post a message to every logged in user",
    "name": "send_wall_message",
    "group": "Queue",
    "version": "2.0.0",
    "description": "<p>Post a message to the team</p>",
    "filename": "./Scot.pm",
    "groupTitle": "Queue"
  },
  {
    "type": "get",
    "url": "/scot/api/v2/esearch",
    "title": "Search Scot",
    "name": "esearch",
    "group": "Search",
    "version": "2.0.0",
    "description": "<p>search SCOT data in ElasticSearch</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "qstring",
            "description": "<p>String to Search for in Alert and Entry records</p>"
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "Object",
            "optional": false,
            "field": "-",
            "description": ""
          },
          {
            "group": "Success 200",
            "type": "Number",
            "optional": false,
            "field": "-.queryRecordCount",
            "description": "<p>Number of Records Returned</p>"
          },
          {
            "group": "Success 200",
            "type": "Number",
            "optional": false,
            "field": "-.totalRecordCount",
            "description": "<p>Number of all Matching Records</p>"
          },
          {
            "group": "Success 200",
            "type": "Object[]",
            "optional": false,
            "field": "-.records",
            "description": "<p>SearchRecords returned</p>"
          }
        ]
      }
    },
    "filename": "./Scot.pm",
    "groupTitle": "Search"
  }
] });
