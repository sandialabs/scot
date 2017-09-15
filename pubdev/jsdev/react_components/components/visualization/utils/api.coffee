Http = require './http'
{Result,ResultPromise} = require './result'
Utils = require './utils'

# This is a set of commands specifically intended for use with the
# SCOT API.

API =
    fetch: (url)->
        Http.asyncjson "GET",url
            .map (r)->if 'queryRecordCount' of r then r.records else r

    stringify: (data)->
        switch
            when ((typeof data) == "string") then data
            when ((typeof data) == 'number') then data
            when Utils.isArray data then escape (JSON.stringify data)
            when Utils.isObject data then escape (JSON.stringify data)
            else escape (JSON.stringify data)
    
    paramstr: (params) ->
        flattened = []
        for own p,v of params
            if Utils.isArray v
                flattened = flattened.concat ((p+'='+(API.stringify val)) for val in v)
            else
                flattened.push (p+'='+(API.stringify v))
        s = flattened.join '&'
        #s=((p+'='+(JSON.stringify params[p])) for own p of params).join '&'
        if s != ''
            '?'+s
        else
            s
        
    url: (path,params) ->
        url = (window.location.origin) + path
        if 'id' of params
            url += '/'+params.id
            delete params.id
            if 'sub' of params
                url += '/'+params.sub
                delete params.sub
        if 'sub' of params
            throw "{sub: #{params.sub}} provided without an 'id' in API call to #{path}"
        url + (@paramstr params)
        
    entry: (params) ->
        @fetch (@url '/scot/api/v2/entry',params)

    entity: (params) ->
        @fetch (@url '/scot/api/v2/entity', params)

    alertgroup: (params) ->
        @fetch (@url '/scot/api/v2/alertgroup',params)

    alert: (params) ->
        @fetch (@url "/scot/api/v2/alert",params)

    event: (params) ->
        @fetch (@url "/scot/api/v2/event",params)

    tag: (params) ->
        @fetch (@url "/scot/api/v2/tag",params)

    putSignature: (sig) ->
        Http.asyncjson "POST",
    commands:
        server: (argv,data,ctx) ->
            if argv.length < 1
                return Result.err ("server: you must provide a URL to use for the default API server")
            window.API.server = argv[0]
            Result.wrap window.API.server

        help__api: ()=>"""
            SCOT API endpoint helpers

            The API module offers helpers to make it easy to query the
            various endpoints of the SCOT API. Each command has its
            own help defined, so look there for more details if you
            need them. All API commands have a few properties in
            common though:

                1. You specify the URL parameters as a javascript
                object on the command line (or as the sole argument to
                the function if you're calling it from user code).

                2. There are two special parameters that behave
                slightly differently: 'id', and 'sub'. 'id' allows you
                to specify which specific object you're interested in,
                and 'sub' allows you to get items that are referenced
                by the parent object. For example, you can query the
                entity endpoint without id or sub, and you'll get a
                list of entries. If you add the id, you'll get the
                single entry with that id. If you add sub: 'entity',
                you'll get the list of entities associated with that
                entry. This pattern applies to all API endpoints.

            All API functions are available from within your pipeline
            functions under the API namespace (e.g. API.entity).
            
            PROMISES
            
            If you use the API endpoints from inside user code (for
            example mapping the entry helper over a list of ids from
            some other source), be aware that these endpoints are
            asynchronous and thus return ResultPromise instances. If
            you want to turn a list of ResultPromise instances into a
            list of actual instances, use the wait command (see 'help
            wait' for more on that one).
            """

        help__entry: ()->"""
            entry [params]

            Query the /scot/api/v2/entry API endpoint. params is an
            optional object with name/value pairs that will be turned
            into parameters in a GET URL. If you specify an 'id' in
            the params, the path will be changed to
            /scot/api/v2/entry/<id>. You can also supply the 'sub' key
            in the params, which should be the name of a thing that is
            referenced by the entry (for example: sub: 'entity' to get
            the entities associated with the entry). If you provide
            sub, you must also provide an id.

            You can access this from a pipeline function under the
            name API.entry.
            
            Example:
                $ entry id:10987,limit:2
                [ {id:...},{id:...}]

                $ entry id:10987,sub:'entity',limit:1
                [{id:...}]
                
                In the first example, the actual API endpoint queried is
                '/scot/api/v2/entry/10987?limit=2'

                In the second example, the endpoint is
                '/scot/api/v2/entry/10987/entity?limit=1'
            """
            
        entry: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)-> API.entry p
                .map_err (e) ->  ('entry: '+e)
                
        help__alertgroup: ()->"""
            alertgroup [params]

            Query the /scot/api/v2/alertgroup API endpoint. params is an
            optional object with name/value pairs that will be turned
            into parameters in a GET URL. If you specify an 'id' in
            the params, the path will be changed to
            /scot/api/v2/alertgroup/<id>. You can also supply the 'sub' key
            in the params, which should be the name of a thing that is
            referenced by the alertgroup (for example: sub: 'alert' to get
            the alerts associated with the alertgroup). If you provide
            sub, you must also provide an id.

            You can access this from a pipeline function under the
            name API.alertgroup.
            
            Example:
                $ alertgroup id:10987,limit:2
                [ {id:...},{id:...}]

                $ alertgroup id:10987,sub:'alert',limit:1
                [{id:...}]
                
                In the first example, the actual API endpoint queried is
                '/scot/api/v2/alertgroup/10987?limit=2'

                In the second example, the endpoint is
                '/scot/api/v2/alertgroup/10987/alert?limit=1'
            """
           
        alertgroup: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)-> API.alertgroup p
                .map_err (e) ->  ('alertgroup: '+e)
        help__entity: ()->"""
            entity [params]

            Query the /scot/api/v2/entity API endpoint. params is an
            optional object with name/value pairs that will be turned
            into parameters in a GET URL. If you specify an 'id' in
            the params, the path will be changed to
            /scot/api/v2/entity/<id>. You can also supply the 'sub'
            key in the params, which should be the name of a thing
            that is referenced by the entity (for example: sub:
            'entry' to get the entries associated with the entity). If
            you provide sub, you must also provide an id.

            You can access this from a pipeline function under the
            name API.entity.
            
            Example:
                $ entity id:10987,limit:2
                [ {id:...},{id:...}]

                $ entity id:10987,sub:'entry',limit:1
                [{id:...}]
                
                In the first example, the actual API endpoint queried is
                '/scot/api/v2/entity/10987?limit=2'

                In the second example, the endpoint is
                '/scot/api/v2/entity/10987/entry?limit=1'
            """

        entity: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)-> API.entity p
                .map_err (e) ->  ('entity: '+e)


        help__alert: ()->"""
            alert [params]

            Query the /scot/api/v2/alert API endpoint. params is an
            optional object with name/value pairs that will be turned
            into parameters in a GET URL. If you specify an 'id' in
            the params, the path will be changed to
            /scot/api/v2/alert/<id>. You can also supply the 'sub' key
            in the params, which should be the name of a thing that is
            referenced by the alert (for example: sub: 'entry' to get
            the entries associated with the alert). If you provide
            sub, you must also provide an id.

            You can access this from a pipeline function under the
            name API.alert.
            
            Example:
                $ alert id:10987,limit:2
                [ {id:...},{id:...}]

                $ alert id:10987,sub:'entry',limit:1
                [{id:...}]
                
                In the first example, the actual API endpoint queried is
                '/scot/api/v2/alert/10987?limit=2'

                In the second example, the endpoint is
                '/scot/api/v2/alert/10987/entry?limit=1'
            """
           
        alert: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)-> API.alert p
                .map_err (e) ->  ('alert: '+e)
                
        help__event: ()->"""
            event [params]

            Query the /scot/api/v2/event API endpoint. params is an
            optional object with name/value pairs that will be turned
            into parameters in a GET URL. If you specify an 'id' in
            the params, the path will be changed to
            /scot/api/v2/event/<id>. You can also supply the 'sub' key
            in the params, which should be the name of a thing that is
            referenced by the event (for example: sub: 'entry' to get
            the entries associated with the event). If you provide
            sub, you must also provide an id.

            You can access this from a pipeline function under the
            name API.event.
            
            Example:
                $ event id:10987,limit:2
                [ {id:...},{id:...}]

                $ event id:10987,sub:'entry',limit:1
                [{id:...}]
                
                In the first example, the actual API endpoint queried is
                '/scot/api/v2/event/10987?limit=2'

                In the second example, the endpoint is
                '/scot/api/v2/event/10987/entity?limit=1'
            """
            
        event: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)-> API.event p
                .map_err (e) ->  ('event: '+e)

        tag: (argv, data, ctx) ->
            Utils.parsevalue (argv.join ' '), ctx
                .and_then (p)->API.tag p
                .map_err (e)-> ('tag: '+e)
                
module.exports = API
