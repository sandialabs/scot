{newscope} = require './newscope'

class Context
    constructor: ()-> @stack = [{}]

    replace: (s)->@stack = [s]

    top: () -> @stack[0]

    pop: () ->
        if @stack.length > 1
           @stack = @stack[1..]
        
    push: (initial={}) -> initial['--parent--'] = @top(); @stack.unshift (newscope initial,@top())

    clear: ()->@stack = [{}]

    @argnames: (ctx) ->
        illegal=/^([^a-zA-Z_$]|try$|catch$|if$|then$|else$|when$|typeof$|return$)/
        names = {}
        while ctx
            for own name of ctx
                if not name.match illegal
                    names[name] = true
            console.log "update parent to #{parent}"
            if ctx == ctx['--parent--']
                console.log "Parent context problem detected"
                break
            ctx = ctx['--parent--']    
        Object.keys names

    @argvals: (ctx,names) -> ctx[name] for name in names
        
module.exports = Context
