Vec = require './vec'

class BoundingBox
    constructor: (@x=0,@y=0,@w=0,@h=0) ->
    containing: (pts) ->
        @x = pts[0].x()
        @y = pts[0].y()
        @w = 0
        @h = 0
        max_x=pts[0].x()
        max_y=pts[0].y()
        for pt in pts[1..]
            if pt.x() < @x then @x = pt.x()
            if pt.y() < @y then @y = pt.y()
            if pt.x() > max_x then max_x = pt.x()
            if pt.y() > max_y then max_y = pt.y()
        @w = max_x - @x
        @h = max_y - @y
        @
    ul: () -> new Vec [@x,@y]
    left: () -> @x
    right: () -> @x+@w
    top: () -> @y
    bottom: () -> @y+@h
    lr: () -> new Vec [@x+@w, @y+@h]
    contains: (pt) -> (@x <= pt.x() <= @x+@w) and (@y <= pt.y() <= @y+@h)
    bbox: () -> @
        
module.exports = BoundingBox
