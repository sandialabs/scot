History = require './history.js'
Utils = require './utils.js'
{Result,ResultPromise}= require './result.js'

class Shell
    constructor: (@output)->
        @history = new History()
        @output ?= (s)->alert "Warning- output function not defined!!!\n\n" + s
        @commands = {}
        @docs = {}
        @scope = {}
        @context = {}
        @addCommands @getCommands()
        @editor = undefined

    registerEditor: (ed) =>
        ed.setCompletionHandler @doCompletion
        ed.setCommandHandler @doCommand
        @editor = ed
        
    loadSavedData: ()->
        @context.__functions=[]
        recovered =JSON.parse localStorage.getItem 'context'
        if recovered
            @context = recovered
            if @context.__functions
                for func in @context.__functions
                    Utils.parsefunction func.source,@context
                        .and_then (f) => @context[func.name] = f
                        .map_err (e) => console.log "Error recovering function "+func.name+": "+e
            else
                @context.__functions = []
        for own item of @scope
            @context[item]=@scope[item]
        
    addCommands: (cmds) ->
        for cmd,handler of cmds
            if cmd.startsWith "help__"
                name = cmd.slice(6)
                if name
                    @docs[name] = handler
            else
                @commands[cmd] = handler

    addScope: (items) ->
        for own item of items
            @scope[item] = items[item]
            
    splitCommands: (cmd) ->
        #find instances of a single backslash
        re = /[^\\]\\[^\\]/g
        splits=[-2] # start with 0 to get first command
        i=0
        while (i=(re.exec cmd))
            splits.push i.index
        splits.push cmd.length
        (cmd[(splits[i]+2)...splits[i+1]+1] for i in [0...splits.length-1])
            .map (c)->c.trim()
            .map (c)->c.split ' '
            .map (c)->c.map (s)->s.replace "\\\\","\\"
            
    doCommand: (cmd) =>
        cmds = @splitCommands cmd
        data = Result.wrap {}
        i = 0
        for cmd in cmds
            if !(cmd[0] of @commands)
                if i == 0
                  cmd.unshift "wrap"
                else
                  cmd.unshift "map"
            i=1
        @runCommands data,cmds
        
    runCommands: (data,cmds) =>
        for i in [0...cmds.length]
            cmd = cmds[i]
            try
                data = data.map (d)=>
                    @context._ = d
                    @commands[cmd[0]] cmd[1..],d,@context
            catch e
                data = Result.err (cmds[i]+': '+e)
                console.log e
            console.log data
            if data instanceof ResultPromise
                data
                   .progress ((done,total) =>
                       console.log "Progress: #{done}/#{total}"
                       @editor.progress done,total)
                   .map (result) => @runCommands (Result.wrap result),cmds[i+1..]
                data.map_err (msg) => @showError msg
                return
            else if data.is_err()
                break
        data.map_err (e) => @showError e
            .and_then (d) =>
                result = ((@prettyprint d) + '\n')
                @output result
                
    showError: (msg) ->
        @output (msg+"\n")
        Result.err msg

    complete: (commands,stub) =>
        for c in commands
            if c.startsWith stub
                return c
        stub

    doCompletion: (stub) =>
        cmds = @splitCommands stub
        cmd = cmds[cmds.length-1]
        othercmd = cmds[0..-2]
        if !cmd || cmd.length > 1
            stub
        else
            ((othercmd.map (c)->c.join ' ').join ' \\ ')
                .concat ([@complete (Object.keys @commands), cmd[0]]).join ' \\ '
            
    prettyprint: (data) =>
        oneliner = (strs) ->
            len = 0
            for s in strs
                if '\n' in s
                    return false
                len += s.length
            len <= 80
        indented = (n,ob) ->
            s = ""
            if Utils.isArray ob
                ls = ob.map (o)->indented n+2, o
                if oneliner ls
                    s = '[' + ls.join(", ") + ']'
                else
                    s = '[\n'+(' '.repeat n+2) + ls.join(",\n"+' '.repeat n+2) + '\n' + (' '.repeat n) + ']'
                s
            else if typeof(ob) == 'undefined'
                'undefined'
            else if ob == null
                'null'
            else if typeof ob == 'object'
                keys = (k for own k of ob).sort()
                pairs= keys.map (k) -> k + ': ' + (if not k.startsWith '__' then (indented n+2, ob[k]) else "<internal>")
                if oneliner pairs
                    s = '{' + pairs.join(", ") + "}"
                else
                    spaces = ' '.repeat n+2
                    s = '{\n' + spaces + pairs.join(',\n'+spaces) + '\n' + spaces[..-3] + '}'
                s
            else if typeof ob == 'function'
                '[function]'
            else
                JSON.stringify ob
        indented 0, data

    clearContext: () =>
        localStorage.setItem 'context', JSON.stringify {}
        @context = {}
        @loadSavedData()
        Result.wrap @context
        
    clearHistory: () =>
        @history.clear()
        Result.wrap {}
        
    getCommands: () =>
        help: (argv,data,ctx) =>
            getcols = (maxw,ncols,index) ->
                col=0
                cols=[]
                width=0;
                for i in [0...ncols]
                    n = col
                    while index[n][0] % ncols != i
                        n++
                    col = n
                    cols.push index[col][1]
                    width += cols[i]
                    if width > maxw
                        return null
                cols
            columns = (maxw, items) ->
                index=([pos,item.length] for item,pos in items).sort (a,b)->b[1]-a[1]
                len = 0
                maxcols=0
                while len+items[maxcols] < maxw
                    len+=items[maxcols].length
                    maxcols++
                while maxcols > 1
                    cols = getcols maxw,maxcols,index
                    if cols
                        return cols
                return [maxw]
            cmd = ""
            if argv.length > 0
                cmd = argv[0]
            if cmd of @docs && cmd != "help"
                Result.err @docs[cmd]()
            else
                str = ""
                if cmd != "" && !(cmd of @commands)
                    str += "Command \""+cmd+"\" is unrecognized\n"
                else if cmd != ""
                    str += "Sorry, \""+cmd+"\" does not have documentation yet"
                str += ("""
                    Read-Eval-Visualize-Loop (REVL)
    
                    REVL is a tool to make it easier to transform data
                    into a format that can be run through a
                    visualization.  It's built to behave like a
                    command line, in that you can pipe data through
                    various primitive operations to transform
                    it from the source format into a format that can
                    be dumped into one of the visualization tools.

                    Use a single backslash ('\\') to separate commands
                    as you would use the pipe character on a standard
                    command line. Each command has help specifically
                    written for it as well. To view the help for a
                    specific command, type 'help <command>' where
                    <command> is replace with the name of the command
                    you need help with. Every command includes at
                    least one example of how to use it in a realistic
                    context.

                    Some commands take parameters on the command line,
                    and many take function literals to be run on the
                    data being piped though. Command line arguments
                    should be written in coffeescript syntax (see
                    http://coffeescript.org for details).

                    You will often want to access library features
                    from within pipeline functions. These are
                    generally available under the name of the module
                    they come from (Struct,Strings,Poly,etc). The only
                    exception is the list features, which are directly
                    imported without a namespace because they are so
                    commonly used.

                    You can also access the current pipeline data from
                    the command line context using the special name
                    '_'. This allows you to use piped data as initial
                    values, and to use parts of the global data
                    structure from within iterator commands like fold.

                    The commands currently supported in this system
                    are:\n\t""" + (Object.keys @commands).sort().join("\n\t")) 
                Result.err str
                
        help__store: ()->"""
            store &lt;name&gt;
    
            store the current data item in the shell under the given
            name. It can be used from that point forward to recall the
            value inside other expressions.
            """
        
        store: (argv,data,ctx) =>
            if argv.length != 1
                Result.err "store expects input from a pipe, and a name from the command line"
            else
                @context[argv[0]] = data
                localStorage.setItem 'context', JSON.stringify @context
                Result.wrap data
    
        help__clear: ()->"""
            clear [-h]
    
            If -h is supplied, clear command history. Otherwise, clear all
            stored variables from the shell. This also clears your local
            storage, so the variables (or history) will not reappear if
            you reload. Use with caution!  """
           
        clear: (argv,data,ctx) =>
            if argv.length > 0 && argv[0] == '-h'
                @clearHistory()
            else
                @clearContext()
    
        help__history: ()->"""
            history
    
            Return the list of commands currently held in the history
            object."""
    
        history: (argv,data,ctx) =>
            Result.wrap (@history.all())
    
        help__context: ()->"""
            context
    
            context prints out the set of variables that are currently
            defined in the shell.
        """
        
        context: (argv,data,ctx) => Result.wrap @context
     
        help__define: ()->"""
            define &lt;name&gt; &lt;value&gt;
    
            This is another way to add a value to the context. If you want
            to have a function stored in the context, you should use this
            method. Using the store command will work, but only until you
            end your session. With the define command, the source code of
            the function is saved in the browser's localstorage object so
            that the function can be recompiled when the session is
            reloaded.
    
            Example:
                $ define sum (args...)->List.foldl args 0, (a,b)->a+b
                [function]
            """
    
        define: (argv,data,ctx) =>
            name = argv[0]
            src = argv[1..].join ' '
            (Utils.parsevalue src)
                .map (val) =>
                    ctx[name] = val
                    if (typeof val) == 'function'
                        ctx.__functions.push {name: name, source: (src)}
                        localStorage.setItem 'context', JSON.stringify ctx
                    Result.wrap val
                .map_err (e) -> Result.err ('define: '+e)

module.exports = Shell
