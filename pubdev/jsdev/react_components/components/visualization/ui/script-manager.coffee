{ResultPromise,Result} = require '../utils/result'
Http = require '../utils/http'
Struct = require '../utils/struct'

class ScriptManager
    constructor: (@shell,@revl) ->
        script_cmds = (JSON.parse localStorage.getItem 'user-scripts')
        @scripts = {}
        @loadApiScripts()
            .map (scr) => 
                for own name of script_cmds
                    @scripts[name]=
                        body: script_cmds[name].body
                        help: script_cmds[name].help
                        signature_id: script_cmds[name].signature_id
                @registerCommands()
        pub_cmds = (Struct.map ScriptManager.public_commands, (cmd) => cmd.bind @)
        console.log "ScriptManager commands: ",pub_cmds
        @shell.addCommands pub_cmds
        Http.asyncjson "GET","/scot/api/v2/whoami"
            .map (r)=> @whoami = r.user

    @getScript: (owner,name,version) ->
        Http.asyncjson "GET","/scot/api/v2/signature?owner=#{owner}&type=userscript&name=#{name}"
            .and_then (r) =>
                scr = undefined
                if r.queryRecordCount < 1
                    return ResultPromise.failed "No matching scripts found"
                Http.asyncjson "GET","/scot/api/v2/signature/#{parseInt r.records[0].id}"
                    .map (script) =>
                        if !script
                            return ResultPromise.failed "Script failed to load due to mysterious internal errors"
                        if (typeof version) == 'undefined'
                            version = script.latest_revision
                        latest = JSON.parse script.version[version].body
                        body: latest.body
                        help: latest.help
            
    loadApiScripts: () ->
        Http.asyncjson "GET","/scot/api/v2/whoami"
            .and_then (r)=> Http.asyncjson "GET","/scot/api/v2/signature?owner=#{r.user}&type=userscript"
            .and_then (r)=>
                results = []
                @shell.output "Loading scripts from server, please wait...\n"
                for scr in r.records
                    results.push ((Http.asyncjson "GET","/scot/api/v2/signature/#{scr.id}")\
                        .map (s)=>(@shell.output "trying #{s.name}\n"; s))
                ResultPromise.waitreplace results,10
            .and_then (scripts) =>
                console.log "got scripts ",scripts
                for script in scripts
                    current = script.version[script.latest_revision]
                    try
                        {body,help}=JSON.parse current.body
                    catch e
                        @shell.output "Failed to load #{script.name}: #{e}\n"
                        continue
                    if ((typeof body) == 'undefined') or ((typeof help) == 'undefined')
                        @shell.output "Script #{script.name} is incomplete, missing body or help\n"
                    else
                        @scripts[script.name] =
                            body: body
                            help: help,
                            signature_id: script.id
                        @shell.output "Loaded #{script.name}\n"
                ResultPromise.fulfilled @scripts
            .map_err (e) =>@shell.showError  ("Error loading scripts from server: "+e)
        
    runScript: (argv, data, context, script) =>
        console.log "Runscript #{JSON.stringify script}"
        innerScript = (dat,ctx,scr) =>
            console.log "Innerscript, data = #{JSON.stringify dat}, script=#{JSON.stringify scr}"
            if scr.length > 0
                result = (@shell.doCommandQuiet scr[0],dat)
                console.log "Result of innerScript #{scr[0]} = #{JSON.stringify result}"
                if scr.length > 1
                    console.log "executing next part of script (length=#{scr.length}): #{JSON.stringify scr[1..]}"
                    return result.and_then (() => innerScript (Result.wrap {}),ctx,scr[1..])
                else
                    return result
            else
                console.log "Empty script, returning error"
                result = new ResultPromise()
                result.fail('Attempted to execute empty script!')
                return result
        @shell.context.push {}
        # Have to use map here to make sure the context pops *after*
        # the script completes, otherwise for scripts that have wait
        # calls, it will pop before the script finishes and problems
        # will follow.
        val=(innerScript data,@shell.context,script)
            .map (r)=>(@shell.context.pop();r)
            .map_err (e)=>(@shell.context.pop();@shell.showError e)
        val

    save: () ->
        localStorage.setItem 'user-scripts',(JSON.stringify @scripts)

    publish: (publish_set) ->
        console.log "Called publish ",publish_set
        publish_body=(id,script)=>
            ((Http.asyncjson "POST","/scot/api/v2/sigbody",\
                {signature_id:id,body: JSON.stringify script})
                .map ()=>script:name,status:"ok")
        get_sig_id = (name,script)=>
            (Http.asyncjson "GET","/scot/api/v2/whoami")
                .and_then (me)=> Http.asyncjson "GET","/scot/api/v2/signature?owner=#{me.user}&name=#{name}&type=userscript"
                .and_then (res) =>
                    console.log("got #{res.records.length} records")
                    if res.records.length >0
                        console.log "fulfilling with first record (id=#{res.records[0].id}"
                        return ResultPromise.fulfilled res.records[0].id
                        #return Http.asyncjson "GET","/scot/api/v2/signature/#{res.records[0].id}"
                    else
                        console.log "Failing, will post new signature"
                        return ResultPromise.failed("no such signature")
                .err_and_then () =>
                    (Http.asyncjson "POST","/scot/api/v2/signature",\
                        {name:name,description:script.help,type:'userscript'})
                        .map (result)=>result.id
        results = []
        for own name,data of publish_set
            console.log "Publishing #{name}"
            r =(get_sig_id name,data)
                .and_then (id)=>(console.log "got sigid: #{id}";publish_body id,data)
                .map (result)=>(script:name,status:'saved',version:result.version)
            results.push r
        ResultPromise.waitreplace results
        
    saveScript: (name,script,replace)->
        if (name of @scripts) and (replace != name)
            if not (confirm "Saving this script as '#{name}' will replace an existing version. Continue?")
                return Result.err "Cancelled by user"
        @scripts[name] = body: script.body, help:script.help
        @registerCommand name
        @save()
        return Result.wrap "Script saved"

    getScript: (name) -> @scripts[name]

    registerCommand: (name) =>
        console.log "Registering command #{name}"
        if name of @scripts
            {body,help} = @scripts[name]
            commands = {}
            commands[name] = ((argv,data,context) => @runScript argv,(Result.wrap data),context,body)
            if help
                commands['help__'+name] = ((argv,data,context) => help)
            @shell.addCommands commands
        else
            console.log "Error: #{name} doesn't exist as a script!"

    registerCommands: ()->
        for own name of @scripts
            @registerCommand name
            
    @public_commands:
        help__script: (argv) ->
            if argv and argv[0] and ('help__'+argv[0]) of ScriptManager.commands
                ScriptManager.commands['help__'+argv[0]].apply @
            else
                """
                script [help|new|publish|import|edit]
    
                script allows you to work with your personal scripts
                collection. There are several subcommands available. For
                help with each, type
                
                # script help <command>
                  
                Subcommands:
                    help [command] - Display this message, or the help for a specific subcommand
                    new            - Create a new script
                    publish        - Upload a script to the server and make it available to others
                    import         - Get another user's script and make it locally available
                    edit <name>    - Edit a script
                    
                """

        script: (argv,data,context) ->
            console.log "Script command executed"
            if argv.length > 0
                arg = argv[1..]
                if argv[0] == 'help'
                    Result.err (ScriptManager.public_commands.help__script arg)
                else if (not (argv[0] of ScriptManager.commands))
                    Result.err ("Subcommand '#{argv[0]}' was not recognized:\n\n"\
                        +ScriptManager.public_commands.help__script())
                else
                    ScriptManager.commands[argv[0]].apply @,[arg,data,context]
            else
                Result.err (ScriptManager.public_commands.help__script argv)

    @commands:
        help__new: ()->"""
            script new [name]

            Create a new script. This launches the script editor. If
            the script already exists you'll get a warning when you
            save it.
            """

        new: (argv,data,ctx)->
            name=""
            script=undefined
            if argv[0]
                name=argv[0]
                script = @getScript name
                if script
                    return Result.err ("Script #{name} already exists, please use "\
                        + "'script edit' if you wish to open it for editing.")
            @revl.showScriptEditor data,script,name

        help__delete: () -> """
            script delete <name> [-a]

            Delete a script. By default, this will only delete the
            script locally, not on the server. If you want to delete
            all copies of the script, give the -a command switch.

            Examples:
                # script delete old_and_boring
                Script 'old_and_boring' deleted from local cache

                # script delete old_and_boring -a
                Script 'old_and_boring' deleted from local cache and server
            """

        help__edit: () -> """
            script edit <name>

            Open the script editor with the given script loaded. Saves
            will update the script in-place.
            """
            
        edit: (argv,data,ctx)->
            name=""
            script=undefined
            if argv[0]
                name=argv[0]
                script = @getScript name
                if !script
                    return Result.err ("Script #{name} not found, please use "\
                        + "'script new' if you wish to create a new script.")
            @revl.showScriptEditor data,script,name
           
        help__publish: ()->"""
           publish [script names or *]
    
           This command allows you to send your locally-defined
           scripts up to the server so that they are accessible by
           other users, and by you from other browsers. Supply the
           names of the scripts you want to publish on the command
           line, or if you just want to publish all of them, put a
           wildcard ('*'). Note that you can't combine these - either
           specify names, or use the wildcard. If you do both it will
           raise an error ("publish: Unknown scripts: '*'").
    
           Examples:
               $ publish teh_win fastness
               [{script: 'teh_win', status: 'success'}, {script: 'fastness', status: 'success'}]
    
               $ publish *
               [{script: 's1', status: 'success'}, {script: 's2', status: 'success'}, ...] 
          """
    
                
        publish: (argv,data,ctx) ->
            if argv.length < 1
                return Result.err "publish: Please specify script names to publish, or '*' to publish all saved scripts"
            console.log "publish command: argv=",argv
            publish_set = {}
            notfound = []
            if argv[0] == '*'
                publish_set = @scripts
            else
                for name in argv
                    if name of @scripts
                        publish_set[name] = @scripts[name]
                    else
                        console.log "publish: Could not find script: #{name}"
                        notfound.push name
            console.log "publish: this = #{@}"
            if notfound.length != 0
                nf = ("'#{s}'" for s in notfound)
                console.log "Not found: #{nf}" 
                return Result.err "publish: Unknown scripts: #{nf}"
            return @publish publish_set
    
    
        help__import: ()->"""
            import <[user/]script> [as <name>]
    
            If somebody has published a script that you want to
            access, you can import it into your environment with this
            command.
    
            user:   (Optional) The username of the script's owner.
            script: (Required) The name of the script to import.
            name:   (Optional) The name to give it in your environment.
    
            You can republish this script under your own name if you
            want, which will allow you to make changes to fit your own
            needs. If you republish it, the script will be loaded from
            your own repository instead of the original, and you will
            not get updates when the original is updated.
    
            If you want to use the data from the pipeline in the
            pipeline, use the map command and access this utility via
            Script.import in the function body.
                 
            Examples:
                $ import jondoe/superbling
                Script 'superbling' imported from user jondoe as superbling
    
                $ import superbling
                Script 'superbling' imported from user jondoe as superbling
    
                $ import superbling as jdbling
                Script 'superbling' imported from user jondoe as jdbling
    
                $ ['superbling','ultrabling','tehblingerator'] \\
                ..    (s)-> Script.import 'jondoe/#\{s}','jd#\{s}'
                Script 'superbling' imported from user jondoe as jdsuperbling
                Script 'ultrabling' imported from user jondoe as jdultrabling
                Script 'tehblingerator' imported from user jondoe as jdtehblingerator
    
            The first three examples use the command in plain form,
            and the last demonstrates how to apply it to pipeline data.
            """
        # 'this' will be bound to the ScriptManager instance
        import: (argv,data,ctx) ->
            pat = /^(([a-zA-Z0-9_]+)\/)?([a-zA-Z0-9_]+)( +as +([a-zA-Z0-9_]+))?$/
            [_,_,user,script,_,name] = (argv.join ' ').match pat
            #@shell.output "user=#{user},script=#{script},name=#{name}"
            ScriptManager.getScript(user,script)
                .and_then (scr) =>
                    @saveScript name,scr
                        .map (_)->"Script '#{script}' imported from user #{user} as #{name}"
                    
module.exports = ScriptManager
