{Result} = require './result'
Context = require '../ui/context'

Utils = 
    isArray: Array.isArray || (value) -> {}.toString.call(value) is '[object Array]'
    isObject: (ob) -> (typeof ob)=="object" && (ob instanceof Object) && (!Utils.isArray ob)
    isNumber: (val) -> typeof(val) == 'number'
    smartcmp: (a,b) ->
        switch
            when (Utils.isNumber a) and Utils.isNumber b then a-b
            when (Utils.isNumber a) and !Utils.isNumber b then -1
            when (Utils.isNumber b) and !Utils.isNumber a then 1
            when a < b then -1
            when a == b then 0
            else 1

    # This is a very, very dirty hack to allow local variables to be
    # defined. I sincerely hope that there is a better way, but for
    # now it seems to work.
    parsefunction: (txt,ctx) ->
        try
            names = Context.argnames ctx
            src = "("+(names.join ',')+')-> '+txt
            proc = (CoffeeScript.eval src).apply ctx, (Context.argvals ctx,names)
            
            if (typeof proc) != "function"
                Result.err ("Expected a function, got \""+txt+"\"")
            else
                Result.wrap proc
        catch e
            Result.err (""+e)
                
    parsevalue: (txt,ctx) ->
        try
            names = Context.argnames ctx
            src = "(("+(names.join ',')+')->'+txt+')'
            exp = (CoffeeScript.eval src).apply ctx, (Context.argvals ctx,names)
            if typeof(exp) == "undefined"
                Result.err "Expected a value, got nothing"
            else
                Result.wrap exp
        catch e
            Result.err ("Parse error: "+e)

    hsv2rgb: (h,s,v) ->
        if s <= 0
            return {r: v, g: v, b: v}
        hh = h*6
        if hh >= 6
            hh = 0
        i = Math.floor hh
        ff = hh - i
        p = v * (1 -s)
        q = v * (1 - (s*ff))
        t = v * (1 - (s * (1 - ff)))
        switch i
            when 0 then {r: v, g: t, b: p}
            when 1 then {r: q, g: v, b: p}
            when 2 then {r: p, g: v, b: t}
            when 3 then {r: p, g: q, b: v}
            when 4 then {r: t, g: p, b: v}
            when 5 then {r: v, g: p, b: q}
            else {r:v, g: p, b: q}
                
    pickColor: (index,max=20) ->
        if index >= max
            max = index+1
        if max < 5
            max = 5
        rgb = Utils.hsv2rgb (index/max), 0.7, 0.6
        '#' + ([rgb.r, rgb.g, rgb.b]
            .map (c) -> (Math.floor (c*256)).toString 16
            .join '')
            
    heatColor: (index,max=100) ->
        colors = ["#800",
            "#f80",
            "#ff0"]
        colorscale = d3.scaleLinear()
            .domain [0, colors.length-1]
            .range colors
        datascale = d3.scaleLinear()
            .domain [0,max]
            .range [0,colors.length-1]
        colorscale (datascale index)
        
module.exports = Utils
