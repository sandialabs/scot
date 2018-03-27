History = require './history'
Utils = require '../utils/utils'
Context = require './context'
ScriptManager = require './script-manager'
{Result,ResultPromise}= require '../utils/result'

class Shell
    constructor: (@output,@revl)->
        @history = new History()
        @output ?= (s)->alert "Warning- output function not defined!!!\n\n" + s
        @commands = {}
        @docs = {}
        @scope = {} # used to restore system functions after restoring context
        @context = new Context() # names accessible from user handlers
        @addCommands @getCommands()
        @editor = undefined
        @script_manager = new ScriptManager(@,@revl)

    registerEditor: (ed) =>
        ed.setCompletionHandler @doCompletion
        ed.setCommandHandler @doCommand
        @editor = ed
        
    loadSavedData: ()->
        @context.top().__functions=[]
        recovered =JSON.parse localStorage.getItem 'context'
        if recovered
            @context.replace(recovered)
            if @context.top().__functions
                for func in @context.top().__functions
                    Utils.parsefunction func.source,@context.top()
                        .and_then (f) => @context.top()[func.name] = f
                        .map_err (e) => console.log "Error recovering function "+func.name+": "+e
            else
                @context.top().__functions = []
        for own item of @scope
            @context.top()[item]=@scope[item]
        
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
        console.log "Splitting command #{JSON.stringify cmd}"
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
            
    doCommand: (cmd,data=Result.wrap {}) =>
        console.log "DoCommand #{cmd}, data=#{JSON.stringify data}"
        (@doCommandQuiet cmd,data)
            .map (d) =>
                result = ((@prettyprint d) + '\n')
                @output result
            .map_err (e) => (console.log "fail shell:73,e=#{JSON.stringify e}";@showError e)

    doCommandQuiet: (cmd,data=Result.wrap {}) =>
        console.log "DoCommandQuiet #{cmd}, data=#{JSON.stringify data}"
        cmds = @splitCommands cmd
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
        console.log "runCommands data=#{JSON.stringify data}, commands=#{JSON.stringify cmds}"
        finish = new ResultPromise().map (d) -> (console.log "runcommands finished with #{d}"; d)
        for i in [0...cmds.length]
            cmd = cmds[i]
            console.log "run command #{cmd}"
            try
                data = data.and_then (d)=>
                    @context.top()._ = d
                    @commands[cmd[0]] (cmd[1..]or[]),d,@context.top()
            catch e
                data = Result.err (cmds[i]+': '+e)
                console.log e
            console.log data
            if data instanceof ResultPromise
                return data
                    .progress ((done,total) =>
                        console.log "Progress: #{done}/#{total}"
                        @editor.progress done,total)
                    .and_then (result) =>(@runCommands (Result.wrap result),cmds[i+1..])
            else if data.is_err()
                break
        console.log "succeeded with data ", data, " fulfilling promise ", finish
        data.and_then (d) -> (console.log "fulfilling now"; finish.fulfill d;finish)
            .map_err (e) -> (console.log "fail shell:117";finish.fail e; e)
        finish

    runScript: (data, context, script) =>
        innerScript = (dat,ctx,scr) =>
            if scr.length > 0
                result = (@doCommand scr[0],dat)
                console.log "Result of innerScript #{scr[0]} = #{JSON.stringify result}"
                if scr.length > 1
                    result.map (() => innerScript (Result.wrap {}),ctx,scr[1..])
                else
                    result
            else
                console.log "Empty script, returning error"
                result = new ResultPromise()
                result.fail('Attempted to execute empty script!')
                result
        @context.push context
        # Have to use map here to make sure the context pops *after*
        # the script completes, otherwise for scripts that have wait
        # calls, it will pop before the script finishes and problems
        # will follow.
        val=(innerScript data,@context,script)
            .map (r)=>(@context.pop();r)
            .map_err (e)=>(@context.pop();@showError e)
        ResultPromise.wait(val)
                
    showError: (msg) ->
        if typeof msg == 'string'
            @output (msg+"\n")
        else
            @output ((JSON.stringify msg)+'\n')
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
                s = ((JSON.stringify ob).replace /</g,'&lt;').replace />/g,'&gt;'
                if s.length > 50
                    s = "#{s[0...30]}<span class=\"longstring\">#{s[30..]}</span>"
                s
        indented 0, data

    clearContext: () =>
        localStorage.setItem 'context', JSON.stringify {}
        @context.clear()
        @loadSavedData()
        Result.wrap @context.top()
        
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
    
            store the current data item in the shell context under the
            given name. It can be used from that point forward to
            recall the value inside other expressions. If you want to
            keep the value in future browser sessions, use the save
            command to dump the context into localstorage.

            """
        
        store: (argv,data,ctx) =>
            if argv.length != 1
                Result.err "store expects input from a pipe, and a name from the command line"
            else
                @context.top()[argv[0]] = data
                Result.wrap data

        help__save: () ->"""
            save

            Dump the current contents of the context into localstorage
            so that your browser will remember your saved data next
            time you start up. This takes no arguments and does
            nothing with data from the pipe (just forwards it through
            unchanged).
            """
            
        save: (argv,data,ctx) =>
            localStorage.setItem 'context', JSON.stringify @context.top()
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
        
        context: (argv,data,ctx) => Result.wrap @context.top()
     
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
                    val
                .map_err (e) ->  ('define: '+e)

        help__push: () => """
            push [definitions]

            Push a new context frame onto the stack. This is mostly
            used for running scripts, where several commands will
            execute in sequence and may need to store intermediate
            values in the context. For that use, the script gets its
            own frame, which is popped back off after the script
            finishes.

            Push can optionally take an object on the command line,
            which will be used as the initial set of definitions for
            the new context. Each named field in the object will be
            available as a global variable in the context until it is
            popped.
            
            You can use this feature to give yourself some working
            space that's easy to clear when you need to keep some
            temporary values handy for a while.

            Examples:
                # Basic Usage:
                    
                $ push
                  "ok"
                $ [1..4] \\ store x
                  [1, 2, 3, 4]
                $ x
                  [1, 2, 3, 4]
                $ x \\ pop
                  [1, 2, 3, 4]
                $ x
                  undefined

                # More features:
                    
                $ [1..3] \\ push a:12,b:14 \\ store x
                  [1, 2, 3]
                $ x
                  [1, 2, 3]
                $ a
                  12
                $ x \\ (n)->n*n \\ pop
                  [1, 4, 9]
                $ x
                  undefined
                $ a
                  undefined
            """
            
        push: (argv,data,ctx) =>
            frame = Result.wrap {}
            if argv.length > 0
                frame = (Utils.parsevalue (argv.join ' '),ctx)
                    .map (val) =>
                        if Utils.isObject val
                            Result.wrap val
                        else
                            Result.err "Argument must be an object"
            frame.map (f)=>(@context.push(f);data)

        help__pop: ()->"""
            pop

            Pop a frame off of the context stack. You can give
            yourself temporary working space with semi-global
            variables by calling push (see help push for
            details). That puts a new frame on top of the context
            stack, and this takes it off. This command will pass the
            data parameter it receives back out to the other side, so
            your computation can store its value in the parent context
            if you want.

            Example:
                $ push
                  "ok"
                $ [1..4] \\ store x
                  [1, 2, 3, 4]
                $ x
                  [1, 2, 3, 4]
                $ x \\ pop
                  [1, 2, 3, 4]
                $ x
                  undefined

            In the example, a clean context frame is pushed on the
            stack, x is stored into it and retrieved, and then the
            frame is popped off, taking the definition of x with
            it.
            """
        
        pop: (argv,data,ctx) =>
            @context.pop()
            Result.wrap data
            
module.exports = Shell
