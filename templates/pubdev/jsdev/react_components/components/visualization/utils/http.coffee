Utils=require './utils'
{Result,ResultPromise} = require './result'

Http =
    asyncjson: (method,url,data) ->
        console.log "asyncjson #{method} #{url} #{JSON.stringify data}"
        rq = new XMLHttpRequest()
        rq.open method,url,true #true for asynchronous
        ret = new ResultPromise()
        rq.onreadystatechange = () ->
            if this.readyState == 4
                try 
                    if 200 <= rq.status < 400
                        console.log "Fulfill #{method} #{url} with ",rq.response
                        console.log "Data is type #{typeof rq.response}"
                        data = JSON.parse rq.responseText
                        ret.fulfill data
                    else
                        msg = JSON.parse(rq.responseText)['error_msg'] or rq.response
                        console.log "Error in asyncjson: ",msg
                        ret.fail "#{rq.statusText}: #{msg}"
                catch e
                    console.log "Exception in asyncjson: ",e,rq.response
                    ret.fail "#{rq.statusText}: #{rq.response}"
        if data
            rq.send (JSON.stringify data)
        else
            rq.send null
        ret
        
    syncjson: (method,url,data) ->
        rq = new XMLHttpRequest()
        rq.open method,url,false # false for synchronous
        if data
            rq.setRequestHeader "Content-Type", "text/plain"
            rq.send (JSON.stringify data)
        else
            rq.send null
        if 200 <= rq.status < 400
            console.log (JSON.stringify rq)
            data = JSON.parse rq.responseText
            Result.wrap data
        else
            console.log "Error in syncjson: ",rq.statusText
            Result.err "#{rq.statusText}: #{rq.response}"
            
    commands:
        help__get_s: () ->"""
            get_s <URL>

            *Synchronously* fetch JSON data from the given URL using
            the HTTP GET method. If you have data in the pipeline
            going in, it will be sent to the server as the request
            body in JSON format.

            This command operates in synchronous mode, which means
            your browser will stop until the request completes. For an
            interactive command line, this typically isn't a problem,
            but if your request might take a long time and you want do
            use the browser for other things in the mean time, use the
            plain 'get' command instead.

            Example:
                $ get_s '/jsonstuff' \\ (item)->item.name

            The example fetches a list of somethings from foo.com and
            extracts the name field of each one, returning a list of
            names.
            """
        
        get_s: (argv,d,ctx) ->
            (Utils.parsevalue argv[0],ctx)
                .map_err (e) ->  ("You must provide a valid URL on the command line")
                .and_then (url) -> Http.syncjson "GET",url,d
                .map_err (e) ->  ("get: "+e)

        help__get: () -> """
            get <URL>

            This is the asynchronous version of the HTTP GET
            method. Use it to fetch JSON formatted data from a remote
            server. The data will be automatically parsed into
            javascript objects compatible with the command pipeline.

            This command operates in asynchronous mode, which means
            that you should be able to interact with your browser
            while the request is waiting to be fulfilled. The command
            line will still wait until the request is fulfilled and
            finish running the remaining pipeline at that time.

             Example:
                $ get_s '/jsonstuff' \\ (item)->item.name

            The example fetches a list of somethings from foo.com and
            extracts the name field of each one, returning a list of
            names.
            """
        
        get: (argv,d,ctx) ->
            (Utils.parsevalue argv[0],ctx)
                .map_err (e)-> ("You must provide a valid URL on the command line: "+e)
                .and_then (url)-> Http.asyncjson "GET",url,d
                .map_err (e) -> ("get: "+e)

        help__put: () -> """
            put <URL>

            Send data to the server using the HTTP PUT method. Data
            can be embedded in the URL or it can be provided from the
            pipeline. Any data coming in to the put command on the
            pipeline will be sent to the server as the request body.

            Example:
                $ {superbling: true} \\ put "/myaccount/set"

            The example sets superbling on your account.
            """
        
        put: (argv,d,ctx) ->
            (Utils.parsevalue argv[0],ctx)
                .map_err (e) ->  "You must provide a valid URL on the command line"
                .and_then (url) -> Http.asyncjson "PUT",url,d
                .map_err (e) -> (console.log("put err: #{e}");("put: "+e))
                
        post: (argv,d,ctx) ->
            (Utils.parsevalue argv[0],ctx)
                .map_err (e) ->  "You must provide a valid URL on the command line"
                .and_then (url) -> Http.asyncjson "POST",url,d
                .map_err (e) -> (console.log("post error: #{e}");("post: "+e))
                
module.exports = Http
