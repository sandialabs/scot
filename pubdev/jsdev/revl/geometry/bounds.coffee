class BBox
    constructor: (@x,@w,@y,@h)->

    intersects: (other) ->
        delta = (a,da,b,db)->Math.abs ((a+da/2)-(b+db/2))
        ((((delta @x,@w,other.x,other.w)*2) < (@w+other.w)) and
           ((delta @y,@h,other.y,other.h)*2) < (@h+other.h))

    splitX: () -> [@x,@x+@w/2,@x+@w]
    splitY: () -> [@y,@y+@h/2,@y+@h]

    left: () -> @x
    right: () -> @x+@w
    top: ()->@y+@h
    bottom: ()->@y
    bbox: () -> @
    
    contains: (geom) ->
        bx = geom.bbox()
        ((@left() <= bx.left()) and (@right() >= bx.right())  \
            and (@top() >= bx.top()) and (@bottom() <= bx.bottom()))
        
    @fromPoints: (ptsiter) ->
        x = undefined
        w = 0
        y = undefined
        h = 0
        pts.forEach (p)->
            if (typeof x)=='undefined' or p.x < x
                x = p.x
            if (typeof y) == 'undefined' or p.y < y
                y = p.y
            w = max(w,p.x-x)
            h = max(h,p.y-y)
        new Geometry.Bounds2 x,w,y,h

module.exports = BBox
