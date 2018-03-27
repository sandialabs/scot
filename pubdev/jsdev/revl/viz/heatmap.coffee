class Heatmap
    constructor: (boundaries={}) ->
        @boundaries = {}
        @total_score = 0
        @setBoundaries boundaries
        
    setBounaries: (boundaries) ->
        for own name,bound of boundaries
            @boundaries[name] =
                poly:
                    regions: bound
                    inverted: false
                score: 0
                
    incr: (name,amount=1) ->
        cell = @boundaries[name]
        if not cell
            throw "No such heatmap cell: "+name
        cell.score += amount
        @total_score += amount

    populate: (data, access=(x)->x) ->
        for own name,value of data
            @incr name, access value
    
    
module.exports = Heatmap
