Vec = require '../geometry/vec'
{feq,fzero,fgt,fgte,fle} = require '../geometry/eps'

#this is an implementation of a high-dimensional space partitioning
#tree. The idea is that you can use this to find clusters of items
#even in a high-dimensional space by finding items that are in a
#common subtree. The data structure is sparse because of the
#exponential growth nature of the tree (50 dimensions would require
#2**50 children for each node if it was fully populated). This tree
#should only grow in proportion with the actual data it stores, but
#should allow spatial clustering based on the hierarchy of point
#locations. You can use this in combination with the dimensionality
#reduction code (pca) to first find the most important dimensions in
#your data, then find clusters in that subspace.
 
class Nspace
    @MaxLoad = 5
    @Node: class Node
        constructor: (bounds) ->
            @bounds = bounds[..]
            @items = []
            @childpaths = {}
            @childlist = []
    
        insert: (item,vec) ->
            if not @contains vec
                return
            if @children().length != 0
                (@getChildFor vec).insert item,vec
            else
                @items.push [item,vec]
                if @items.length >= Nspace.MaxLoad
                    @split()
    
        split: () ->
            for [item,coords] in @items
                (@getChildFor coords).insert item,coords
            @items = []
    
        low: (i)-> @bounds[i][0]
        
        high: (i) -> @bounds[i][1]
        
        getChildFor: (vec) ->
            section = @childpaths
            newbound = []
            for i in [0...vec.dim()]
                if (@low i) <= (vec.nth i) < ((@low i)+(@high i))/2
                    section.low ?= {}
                    section = section.low
                    newbound.push [(@low i), ((@low i)+(@high i))/2]
                else
                    section.high ?= {}
                    section = section.high
                    newbound.push [((@low i)+(@high i))/2,(@high i)]
            if (typeof section.node) is "undefined"
                section.node = new Nspace.Node newbound
                @childlist.push section.node
            section.node
            
        contains: (vec) ->
            for i in [0...vec.dim()]
                if not ((@low i) <= (vec.nth i) <= (@high i))
                    return false
            true

        leaves: () ->
            if @children().length != 0
                [].concat.apply [],(child.leaves() for child in @children())
            else
                [@]

        children: () -> @childlist

    constructor: () ->
        @coord_index={}
        @lowbound=0 # 0 coord must be included for all dimensions
                    # because of default value in sparse vectors
        @highbound=0
        @nextdim = 0
        @items = []

    # coords should be a list of name/value pairs. The names will be
    # converted into indices as a side effect of insertion. When all
    # items have been inserted, call subdivide() to insert all items
    # into the space partitioning tree. The two step process allows me
    # to figure out how many dimensions are needed in each
    # node. Otherwise you'd have to know ahead of time what the
    # dimension of the data set is, which is inconvenient in a
    # pipeline based system.
    insert: (item,coords) ->
        @items.push [item,coords]
        for coord in coords
            @coord_index[coord[0]] ?= @nextdim++
            @updatebounds coord
                
    updatebounds: (coord) ->
        if coord[1] < @lowbound
            @lowbound = coord[1]
        if coord[1] > @highbound
            @highbound = coord[1]
        # ensure non-zero size for all bounds by adding random noise
        # less than one
        while feq @lowbound,@highbound
            @lowbound -= Math.random()
            @highbound += Math.random()
 
    subdivide: () ->
        bounds = ([@lowbound,@highbound] for i in [0...@nextdim])
        @root = new Nspace.Node bounds
        for item in @items
            coords = (0 for b in bounds)
            for coord in item[1]
                coords[@coord_index[coord[0]]] = coord[1]
            @root.insert item,new Vec coords
        @items = undefined
        @

    leaves: () -> @root.leaves()

    @commands:
        help__Nspace: () -> """
           Nspace (class)

           Nspace is a space partitioning tree that works in an
           arbitrary number of dimensions. Its purpose is to make it
           easy to take vectors of high-dimensional data and find
           which ones are close together (i.e. spatial clustering),
           and to do other high-dimensional spatial calculations (find
           items within a distance of some point, within a bounding
           box, intersecting some polytope, etc).

           The main mode of use is as an accumulator on the command
           line in the fold commands (foldl, foldr). It allows you to
           build up the high-dimensional space incrementally by just
           inserting data points. Each data point is represented as a
           list of pairs, where the first element of the pair is the
           *name* of the coordinate (more on this later), and the
           second element is the value of the coordinate. For example,
           if you are just using the standard 3d coordinate system,
           you could use something like this:

               [item1, [[x,1],[y,33],[z,-10]]]

           The power of this representation is that it allows you to
           use an arbitrary naming scheme for your coordinates. Let's
           say you want to cluster a large collection of messages
           according to the domain names that are harvested from them
           as flair in SCOT. You could just decide that each domain
           name will be a coordinate, and pass in points as the data
           element followed by the list of domains it references, with
           ones for the values:
                
               [msg1, [["foo.com",1],["bar.com",1],["baz.com",1]]]
               
           Not all messages will reference all domains (obviously),
           but you don't have to try to precompute the full set of
           domains because the Nspace will accumulate them for you. If
           your message set references 100 domains in total, but any
           given message only references two or three, then the Nspace
           will have 100 dimensions after the inserts are
           complete. Each coordinate that is not defined for an
           inserted item is set to zero automatically.

           The downside of this incremental load process is that you
           have to wait until all of your inserts are done, then call
           the 'subdivide' function in order to actually build the
           data structure. In practice, this adds one more element to
           the pipeline in your command.

           Here is a command you can try that uses Nspace to draw a
           quadtree based on random data:

               [1..100] \\
               foldl new Nspace (s,pt) -> s.insert pt,[['x',Math.random()],['y',Math.random()]]; s  \\
               (s)->s.subdivide() \\
               (sp)->sp.leaves() \\
               (l)->l.bounds \\
               (bnd)->List.zip bnd \\
               (pts)->[[pts[0][0],pts[0][1]],[pts[0][0],pts[1][1]],[pts[1][0],pts[1][1]],[pts[1][0],pts[0][1]]] \\
               (pts)->(polygon pts).scale 200 \\
               into (polys)->{polygons: polys} \\
               draw

            This command starts by generating a list of length 100,
            then converts that into a list of 100 points. Each point
            has its index number for data, and randomly generated 'x'
            and 'y' coordinates.

            The points are inserted into an empty Nspace object using
            the foldl command.

            The resulting data structure is finalized using the ()->
            map construct to call subdivide()

            The leaf nodes are collected (these are the only nodes
            with actual data)

            The bounds of each leaf node are found (this gives a lower
            and upper bound on each coordinate dimension)

            The bounds lists are re-zipped so that they become a
            lower-left corner and upper right corner
            ([[x_low,x_high],[y_low,y_high]] => [[x_low,y_low],[x_high,y_high]])

            The remaining corners of a square are created by copying
            the appropriate parts of the lower-left and upper-right
            corners into a lower-right and upper-left.

            Polygons are created from those point lists, and scaled up
            by a factor of 200 to make them visible

            The list of polygons is converted into a drawable object
            (basically just put a list of polygons into an object
            under the name 'polygons')

            Finally, the whole mess is piped into the draw function,
            which puts a colorful rendering of the tree on screen.

            This object is designed to be used with dimensionality
            reduction code, see 'help pca' for more details.
            """


module.exports = Nspace
