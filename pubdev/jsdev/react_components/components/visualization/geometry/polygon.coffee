Shell = require '../ui/shell'
Vec = require './vec'
BoundingBox = require './boundingbox'
Edge = require './edge'
{fgt,flt} = require './eps'

polygon = (pts) -> new Polygon (pts.map (p)->new Vec p)

class Polygon
    constructor: (verts) ->
        @verts = verts[..]
    edges: () -> (new Edge @verts[i],@verts[(i+1)%@verts.length]) for i in [0...@verts.length]
    contains: (pt) ->
        # shoot a ray to the right from the point and see how many
        # edges it intersects. Even means point is outside, odd means
        # point is inside
        # 
        # To test if the edge crosses: at least one end has to be to
        # the right of the point, and it must have one end above and
        # one below the point.
        count=0
        for i in [0...@verts.length]
            j = (i+1)%@verts.length
            xdesc = ((@verts[j].x()-@verts[i].x())*(pt.y()-@verts[i].y()) / \
                     (@verts[j].y()-@verts[i].y())+@verts[i].x())

            if ((fgt @verts[i].y(), pt.y()) != (fgt @verts[j].y(), pt.y())) and (flt pt.x(), xdesc)
                count++
        (count % 2) != 0
    containsEdge: (edge) ->
        if !@contains edge.p1
            return false
        for e in @edges()
            if e.crosses edge
                return false
        true
    containsPoly: (poly) ->
        for e in poly.edges()
            if !@containsEdge e
                return false
        true
    center: () ->
        cx = 0
        cy = 0
        for pt in @verts
            cx += pt.x()
            cy += pt.y()
        cx/=@verts.length
        cy/=@verts.length
        new Vec [cx,cy]

    toPbool: () ->
        regions: [[v.x(),v.y()] for v in @verts]
        inverted: false
    @fromPbool: (pb)-> (polygon region) for region in pb.regions
    intersect: (poly) -> Polygon.fromPbool (PolyBool.intersect poly.toPbool(), @toPbool())
    union: (poly) -> Polygon.fromPbool (PolyBool.union poly.toPbool(),@toPbool())
    trim: (poly) -> (@intersect poly)[0]
    subtract: (poly) -> Polygon.fromPbool (PolyBool.difference poly.toPbool(),@toPbool())
    xor: (poly) -> Polygon.fromPBool (PolyBool.difference poly.toPbool(),@toPbool())
    bbox: () ->
        if @bounds
            @bounds
        else
            @bounds = new BoundingBox().containing @verts
            @bounds
    scale: (factor) ->
        @verts= ((vert.scale factor) for vert in @verts)
        @

module.exports =
    Polygon: Polygon
    polygon: polygon
