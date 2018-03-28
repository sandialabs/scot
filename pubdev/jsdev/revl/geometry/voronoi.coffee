{polygon,Polygon} = require './polygon'


class Voronoi
    constructor: (@points,boundary)->
        @setBoundary boundary
        
    addCell: (pt) ->
        if !@boundary or (@boundary and @boundary.contains pt)
            @points.push pt
        else
            throw "Error - can't add point outside voronoi diagram boundary!"
        @
        
    setBoundary: (poly) ->
        @boundary=poly
        if @boundary
            for pt in @points
                if not (@boundary.contains pt)
                    throw "Error - new voronoi diagram boundary doesn't contain all points!"
        @
        
    layout: () ->
        bbox = @boundary.bbox()
        @polygons = []
        polys = d3.voronoi()
            .extent [bbox.ul().coords, bbox.lr().coords]
            .polygons (@points.map (pt)->pt.coords)
            .map (pts) -> polygon pts
        console.log "polygons in voronoi: "+JSON.stringify polys
        if @boundary and (@boundary instanceof Polygon)
            for poly in polys
                trimmed = poly.trim @boundary
                if trimmed then @polygons.push trimmed
        else
            @polygons = polys
        @

    drawable: () ->
        polygons: @polygons

module.exports = Voronoi
