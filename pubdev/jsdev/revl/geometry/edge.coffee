Vec = require './vec'

class Edge
    constructor: (@p1, @p2) ->
    norm: ()->(@p2.sub @p1).norm()
    crosses: (edge) ->
        ((edge.p1.edgetest @) != edge.p2.edgetest @) and
        ((@p1.edgetest edge) != @p2.edgetest edge)
    contains: (pt) ->
        v1 = pt.sub @p1
        me = @p2.sub @p1
        ratio = (v1.nth 0)/(me.nth 0)
        (flte 0,ratio) and (flte ratio,1) and (me.scale ratio).eq v1
    direction: () -> @p2.sub @p1
    parallel: (edge) ->
        feq 1,(@direction().normalize().dot (edge.direction().normalize()))
    #calculate point at which edges *would* intersect, if they were
    #infinitely long. Return undefined if edges will not intersect
    intersection: (edge) ->
        if @parallel edge
            return undefined
        [x1,y1,x2,y2] = [(@p1.nth 0),(@p1.nth 1), (@p2.nth 0), (@p2.nth 1)]
        [x3,y3,x4,y4] = [(edge.p1.nth 0),(edge.p1.nth 1), (edge.p2.nth 0), (edge.p2.nth 1)]
        denom = ((x1-x2)*(y3-y4) - (y1-y2)*(x3-x4))
        n1 = (x1*y2 - y1*x2)
        n2 = (x3*y4 - y3*x4)
        p1 = (n1*(x3-x4) - (x1-x2)*n2) / denom
        p2 = (n1*(y3-y4) - (y1-y2)*n2) / denom
        new Vec [p1,p2]

module.exports = Edge
