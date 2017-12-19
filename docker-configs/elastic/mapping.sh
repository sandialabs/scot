no_proxy=localhost

until $(curl -vvv --noproxy elastic --output /dev/null --fail --silent --head -u elastic:changeme http://elastic:9200/); do    printf '.';     sleep 5; done

echo "Deleting Existing SCOT index";
curl --noproxy elastic -u elastic:changeme -XDELETE elastic:9200/scot

echo "Creating SCOT index";
curl --noproxy elastic -u elastic:changeme -XPUT elastic:9200/scot?pretty=1 -d '
{
    "settings": 
        {"analysis": 
            {"analyzer": 
                {
                    "scot_analyzer": 
                        {
                            "tokenizer": "my_tokenizer"
                        }
                },
                "tokenizer": 
                    {
                        "my_tokenizer": 
                            {
                                "type": "uax_url_email"
                            }
                    }
            }
        }
    ,    
    "mappings": {
        "alert": {
            "_all": { "store": true },
            "properties": {
                "id":               { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "alertgroup":       { "type": "integer" },
                "parsed":           { "type": "integer" },
                "data":             { "type": "object" },
                "data_with_flair":  { "type": "object" },
                "entry_count":      { "type": "integer" },
                "promotion_id":     { "type": "integer" },
                "status":           { "type": "string", "index": "not_analyzed" },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" }

            }
        },
        "alertgroup": {
            "_all": { "store": true },
            "properties": {
                "id":               { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "body":             { 
                    "type": "string",
                    "index": "not_analyzed",
                    "fields": {
                        "raw": {
                            "type": "string",
                            "index": "not_analyzed"
                        }
                    }
                },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "promotion_id":     { "type": "integer" },
                "parsed":           { "type": "integer" },
                "subject":          { "type": "string" },
                "source":           { "type": "string", "index": "not_analyzed" },
                "tag":              { "type": "string", "index": "not_analyzed" },
                "views":            { "type": "integer" },
                "view_history":     { "type": "object" },
                "message_id":       { "type": "string" },
                "body_plain":       { "type": "string" },
                "status":           { "type": "string", "index": "not_analyzed" },
                "open_count":       { "type": "integer" },
                "closed_count":     { "type": "integer" },
                "promoted_count":   { "type": "integer" },
                "alert_count":      { "type": "integer" }
            }
        },
        "appearance": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "target":   { 
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "type":     { "type": "string", "index": "not_analyzed" },
                "value":    { "type": "string", "index": "not_analyzed" },
                "apid":     { "type": "integer" },
                "when":     { "type": "date", "format": "strict_date_optional_time||epoch_second" }
            }
        },
        "checklist": {
            "_all": { "store": true },
            "properties": {
                "id":               { "type": "integer" },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "subject":          { "type": "string" },
                "description":      { "type": "string" }
            }
        },
        "entity": {
            "_all": { "store": true },
            "properties": {
                "id":           { "type": "integer" },
                "entry_count":  { "type": "integer" },
                "value":        { "type": "string", "index": "not_analyzed" },
                "type":         { "type": "string", "index": "not_analyzed" },
                "data":         { "type": "object", "enabled": false }
            }
        },
        "entry": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "target":   { 
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "body":             { 
                    "type": "string",
                    "index": "not_analyzed",
                    "fields": {
                        "raw": {
                            "type": "string",
                            "index": "not_analyzed"
                        }
                    }
                },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "parsed":           { "type": "integer" },
                "summary":          { "type": "boolean" },
                "task":             {
                    "properties":   {
                        "when":     { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                        "who":      { "type": "string", "index": "not_analyzed" },
                        "status":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "is_task":          { "type": "boolean" },
                "parent":           { "type": "integer" }
            }
        },
        "event": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "entry_count":  { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "promotion_id":     { "type": "integer" },
                "promoted_from":   { "type": "integer" },
                "source":           { "type": "string", "index": "not_analyzed" },
                "tag":              { "type": "string", "index": "not_analyzed" },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "views":            { "type": "integer" },
                "view_history":     { "type": "object" },
                "subject":          { "type": "string" },
                "status":           { "type": "string", "index": "not_analyzed" }
            }
        },
        "file": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "target":   { 
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "entry_target": {
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "filename":     { "type": "string" },
                "size":         { "type": "integer" },
                "notes":        { "type": "string" },
                "entry":        { "type": "integer" },
                "directory":    { "type": "string", "index": "not_analyzed" },
                "md5":          { "type": "string", "index": "not_analyzed" },
                "sha1":         { "type": "string", "index": "not_analyzed" },
                "sha256":       { "type": "string", "index": "not_analyzed" }
            }
        },
        "guide": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties":   {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "entry_count":      { "type": "integer" },
                "subject":          { "type": "string" },
                "applies_to":       {  "type": "string" }
            }
        },
        "history": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "target":   { 
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "who":  { "type": "string", "index": "not_analyzed" },
                "when": { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "what": { "type": "string" }
            }
        },
        "incident": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "entry_count":      { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "promotion_id":     { "type": "integer" },
                "source":           { "type": "string", "index": "not_analyzed" },
                "tag":              { "type": "string", "index": "not_analyzed" },
                "subject":          { "type": "string" },
                "type":             { "type": "string", "index": "not_analyzed" }, 
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "promoted_from":    { "type": "integer" },
                "reportable":       { "type": "boolean" },
                "occurred":         { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "discovered":       { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "reported":         { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "status":           { "type": "string", "index": "not_analyzed" },
                "category":         { "type": "string", "index": "not_analyzed" },
                "sensitivity":      { "type": "string", "index": "not_analyzed" },
                "deadline_status":  { "type": "string", "index": "not_analyzed" }
            }
        },
        "intel": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "entry_count":      { "type": "integer" },
                "owner":            { "type": "string" },
                "groups":           { 
                    "properties": {
                        "read":     { "type": "string", "index": "not_analyzed" },
                        "modify":   { "type": "string", "index": "not_analyzed" }
                    }
                },
                "source":           { "type": "string", "index": "not_analyzed" },
                "tag":              { "type": "string", "index": "not_analyzed" },
                "subject":          { "type": "string" },
                "updated":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "created":          { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "when":             { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "views":            { "type": "integer" },
                "view_history":     { "type": "object" }
            }
        },
        "link": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "target":   { 
                    "properties": { 
                        "id":   { "type": "integer" },
                        "type": { "type": "string", "index": "not_analyzed" }
                    }
                },
                "when": { "type": "date", "format": "strict_date_optional_time||epoch_second" },
                "entity_id":    { "type": "integer" },
                "value":        { "type": "string", "index": "not_analyzed" }
            }
        },
        "source": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "value":    { "type": "string", "index": "not_analyzed" },
                "notes":    { "type": "string" }
            }
        },
        "tag": {
            "_all": { "store": true },
            "properties": {
                "id":   { "type": "integer" },
                "value":    { "type": "string", "index": "not_analyzed" },
                "notes":    { "type": "string" }
            }
        }
    }
}
'

