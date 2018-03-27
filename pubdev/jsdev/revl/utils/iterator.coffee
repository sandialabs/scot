class Iterator
    constructor: (@nxt) ->
        @elt = @nxt()
        
    end: ()-> (typeof @elt) == "undefined"
    
    next: () ->
        if @end()
            return undefined
        ret = @elt
        @elt = @nxt()
        ret

    collect: () ->
        ret = []
        while !@end()
            ret.push @next()
        ret

    map: (f) ->
        if !@end()
            @elt = f @elt
            oldnxt = @nxt
            @nxt = () ->
                chk = oldnxt()
                if (typeof chk) != "undefined"
                    chk = f chk
                chk

    forEach: (f) ->
        while !@end()
            f @next()

module.exports = Iterator
