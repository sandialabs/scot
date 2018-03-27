
class Vec
    constructor: (coords) -> @coords = coords[..]
    add: (other) -> new Vec (((other.nth i)+(@nth i)) for i in [0...@coords.length])
    sub: (other) -> new Vec (((@nth i)-(other.nth i)) for i in [0...@coords.length])
    dot: (other) -> (((@nth i)*(other.nth i)) for i in [0...@coords.length]).reduce (a,b) -> a+b
    norm: () -> (@dot @)
    normalize: ()-> @scale 1.0/(@norm())
    scale: (f) -> new Vec ((f*x) for x in @coords)
    x: () -> @nth 0
    y: () -> @nth 1
    z: () -> @nth 2
    w: () -> @nth 3
    dim: () -> @coords.length
    nth: (n) ->
        if n >= @coords.length 
            throw "Error: out of bounds access on vector"
        else
            @coords[n]
    cross2: (other) -> ((@nth 1) * (other.nth 0)) - ((@nth 0) * (other.nth 1))
    eq: (other) ->
        for i in [0...@coords.length]
            if not feq (@nth i), (other.nth i)
                return false
        true
    edgetest: (edge)->
        anchor = edge.p2.sub edge.p1
        test = @.sub edge.p1
        result= anchor.cross2 test
        switch
            when flt result, 0 then -1
            when fgt result, 0 then 1
            when feq result, 0 then 0
            
    leftof: (edge) -> (@edgetest edge) < 0
    rightof: (edge) -> (@edgetest edge) > 0
    colinear: (edge) -> (@edgetest edge) == 0
    
        
module.exports = Vec
