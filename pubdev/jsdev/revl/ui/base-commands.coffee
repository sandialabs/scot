Utils = require '../utils/utils'
List = require '../utils/list'
Struct = require '../utils/struct'
{Result,ResultPromise} = require '../utils/result'

BaseCommands =
    help__into: ()->"""
        into &lt;function&gt;
    
        Take the input and apply the function directly to it,
        regardless of its internal format. Normally, data is checked
        to see if it is list-like or not before deciding what the
        behavior of map and fold, etc should be. In this case, you're
        saying that you just want whatever the contents of the data is
        to be handed to you directly in one piece.
        
        Example:
           $ [1,2,3] \\ into (f) -> 12
           12
        Without into:
           $ [1,2,3] \\ (f)->12
           [12,12,12]
        """
        
    into: (argv,d,ctx) =>
        console.log "into(proc)"
        Utils.parsefunction (argv.join " "),ctx
            .and_then (proc) ->
                try
                    Result.wrap (proc d)
                catch e
                    console.log "exception "+e
                    Result.err (''+e)
            .map_err (e) -> console.log "error";Result.err ("into(proc): "+e)

    help__map: ()->"""
        map &lt;function&gt;

        Map applies the given function to the data. If the data is an
        array (list), map will apply the function to each element of
        the list and return a list containing the results. If the data
        is an object, proc will be called on each item in the struct
        with the value and the key as args (yes, in that order - this
        way you can ignore the key most times, which is what you
        probably want).

        
        Example:
          $ [1,2,3,4] \\ map (n) -> n*2
          [2,4,6,8]
          $ {foo: 12} \\ map (v,k) -> v*9
          {foo: 108}
        """
        
    map: (argv,ls,ctx) =>
        console.log "map(proc)"
        Utils.parsefunction (argv.join " "),ctx
            .and_then (proc) -> 
                try
                    if Utils.isArray ls
                        Result.wrap (List.map ls, proc)
                    else if Utils.isObject ls
                        Result.wrap (Struct.map ls,proc)
                    else # plain number or something
                        Result.wrap (proc ls)
                catch e
                    Result.err (''+e)
            .map_err (msg) ->  ("map(proc): "+msg)

    help__mapfields: ()->"""
        mapfields field,proc

        mapfield alters only the specified field in the object if the
        data on the pipeline is object-like, or alters the specified
        field of all structs in the list if it is list-like.

        proc should be a function that takes the current value of the
        field, and optionally the struct itself, and returns a new
        value for the named field.

        Example:
            $ {a:1,b:3} \\ mapfield a (n)->n*5
            {a:5,b:3}

            $ {a:7,b:3} \\ mapfield a (n,ob) -> n*ob.b
            {a:21,b:3}
        """
        
    mapfield: (argv,ls,ctx) =>
        console.log "mapfield #{argv[0]}"
        field=argv[0]
        Utils.parsefunction (argv[1..].join " "),ctx
            .and_then (proc) ->
                try
                    if Utils.isObject ls
                        Result.wrap (Struct.mapfield ls,field,proc)
                    else
                        Result.wrap (ls.map (e)->Struct.mapfield e,field,proc)
                catch e
                    Result.err (''+e)
            .map_err (msg)-> ("mapfield: "+msg)
            
    help__tolist: ()->"""
        tolist

        Convert a struct to a list. If argument is a list, it will be
        unchanged. The result is a list of pairs, where the first
        element of each pair is the key for an item in the struct, and
        the second element is the value associated with that key.

        Example:
            $ {a: 1, b: 2} \\ tolist
            [[a,1],[b,2]]
        """

    tolist: (argv,d,ctx) =>  Result.wrap (Struct.tolist d)

    help__tostruct: ()->"""
        tostruct

        Convert a list of pairs into an object (struct) that has an
        entry for each pair in the list. The keys will be the first
        elements of each pair, and the values will be the second
        elements. In other words, create a struct from an association
        list.

        Example:
            $ [[1,'a'],['b',2]] \\ tostruct
            {1: 'a', b: 2}
        """
        
    tostruct: (argv,d,ctx) => Result.wrap (List.tostruct d)
 
    help__mapall: ()->"""
        mapall function
    
        Mapall works on a list of lists. It will proceed through all
        sublists in parallel, taking the next element of each sublist and
        providing them in order as arguments to a single call of the
        function. The resulting value will be appended to the final
        result, which will be a single list of the same length as one of
        the sublists. This is hard to explain in words, so here are some
        examples:
    
          $ [[1,2,3],[1,2,3],[1,2,3]] \\ mapall (a,b,c) -> [a,b,c]
          [[1,1,1],[2,2,2],[3,3,3]]
    
          $ [[1,2,3],[1,2,3],[1,2,3]] \\ mapall (a,b,c) -> a+b+c
          [3,6,9]
    
          $ [[1,2,3],[1,2,3],[1,2,3]] \\ mapall (args...) -> args
          [[1,1,1],[2,2,2],[3,3,3]]
        """

    mapall: (argv,ls,ctx) =>
        console.log "mapall"
        Utils.parsefunction (argv.join " "),ctx
            .and_then (proc) -> 
                try
                    Result.wrap (List.mapall ls,proc)
                catch e
                    Result.err (''+e)
            .map_err (msg) ->  ("mapall(proc): "+msg)
           
    help__filter: ()->"""
        filter function

        Filter calls the given function on each element of the data
        list and only adds the element to the output list if the
        result is truthy (i.e. not false).

        Example:
          $ [1,2,3] \\ filter (n) -> n>=2
          [2,3]
        """
    filter: (argv,ls,ctx) =>
        Utils.parsefunction (argv.join " "),ctx
            .and_then (proc) ->
                if Utils.isArray ls
                    Result.wrap (List.filter ls,proc)
                else if Utils.isObject ls
                    Result.wrap (Struct.filter ls,proc)
                else
                    throw "Can't filter something that is neither object nor list"
            .map_err (msg) ->  ("filter: "+msg)

    help__foldl: ()->"""
        foldl &lt;initial_value&gt; &lt;function(accumulator,next_val)&gt;

        foldl takes an initial value and a function, and repeatedly
        calls the given function on two arguments: the value of an
        accumulator and the value of the next item in the input
        list. This is done left-associatively (hence the 'l' in
        'foldl'), so that the first call to the function consumes the
        initial value with the first list element, and it proceeds in
        order through the list from left to right. foldr is also
        available, which works right-associatively. In this way you
        can do things like add up all of the numbers in a list, or
        concatenate all of the strings in a list, or turn a list of
        pairs into an object with keys and values:

        Examples:
          $ [1,2,3] \\ foldl 0 (acc,n) -> acc+n
          6

          $ ['a','b','c'] \\ foldl "" (acc,n) -> acc+n
          'abc'

          $ [['a', 1],['b',2],['c',3]] \\ foldl {} (acc,n) -> acc[n[0]] = n[1]; acc
          {a: 1, b: 2, c: 3}

          $ ['a','b','c'] \\ foldl 'x' (acc,n) -> '(' + acc + ',' + n + ')'
          ((('x','a'),'b'),'c')
        
        Note in the object example that you have to explicitly return
        the accumulator, otherwise you'll just get undefined (the
        member assignment operator doesn't return anything in
        coffeescript) """
         
    foldl: (argv,ls,ctx) =>
        console.log "foldl"
        args = argv.join ' '
        # parts = args.match(/^([^(]+)(\([^)]*\)\s*->.*)$/m)
        parts = args.match /^([^>]+)(\([a-zA-Z,]*\) *->.*)$/m
        console.log "Parts: "+JSON.stringify parts
        (if !parts
            Result.err "expected an initial value and a function"
        else
            Utils.parsefunction parts[2],ctx
                .and_then (proc) ->
                    Utils.parsevalue parts[1],ctx
                        .and_then (acc) ->
                            try
                                Result.wrap (List.foldl acc, ls, proc)
                            catch e
                                Result.err (''+e)
        ).map_err (e) ->  ("foldl: "+e)

    help__foldr: ()->"""
        foldr &lt;initial_value&gt; &lt;function(next_val,accumulator)&gt;

        foldr takes an initial value and a function, and repeatedly
        calls the given function on two arguments: the value of an
        accumulator and the value of the next item in the input
        list. This is done right-associatively (hence the 'r' in
        'foldr'), so that the first call to the function consumes the
        initial value with the last list element, and it proceeds in
        order through the list from right to left. foldl is also
        available, which works left-associatively. In this way you
        can do things like add up all of the numbers in a list, or
        concatenate all of the strings in a list, or turn a list of
        pairs into an object with keys and values:

        Examples:
          $ [1,2,3] \\ foldr 0 (n,acc) -> n+acc
          6

          $ ['a','b','c'] \\ foldr "" (n,acc) -> n+acc
          'abc'

          $ [['a', 1],['b',2],['c',3]] \\ foldr {} (n,acc) -> acc[n[0]] = n[1]; acc
          {a: 1, b: 2, c: 3}

          $ ['a','b','c'] \\ foldr 'x' (n,acc) -> '(' + n + ',' + acc + ')'
          ('a',('b',('c','x')))
        
        Note in the object example that you have to explicitly return
        the accumulator, otherwise you'll just get undefined (the
        member assignment operator doesn't return anything in
        coffeescript) """

    foldr: (argv,ls,ctx) =>
        console.log "foldr"
        args = argv.join ' '
        parts = args.match(/^([^(]+)(\([^)]*\)\s*->.*)$/m)
        (if !parts
            Result.err "expected an initial value and a function"
        else
            Utils.parsefunction parts[2],ctx
                .and_then (proc) ->
                    Utils.parsevalue parts[1],ctx
                        .and_then (acc) ->
                            try
                                Result.wrap (List.foldr ls, acc, proc)
                            catch e
                                Result.err (''+e)
        ).map_err (e) ->  ("foldr: "+e)

    help__group: () ->"""
        group &lt;function(item)&gt;
    
        group takes a list from the input and groups the items into fields
        of an object. The function argument should take an item from the
        list and return the name of the group it belongs with. The value
        returned will be an object with each item assigned to a list under
        the appropriate name.
    
        Examples:
          $ [1,2,3] \\ group (n)-> if n < 3 then 'small' else 'large'
          {small: [1,2], large: [3]}

    """
    
    group: (argv,d,ctx) =>
        console.log "group"
        Utils.parsefunction (argv.join " "),ctx
            .and_then (proc) ->
                try
                    Result.wrap (List.group d, proc)
                catch e
                    Result.err (''+e)
            .map_err (e) ->  ("group: "+e)

    help__zip: ()->"""
        zip

        zip takes a list of lists and returns a new list of lists,
        where the sublists contain all of the elements that have the
        same positions in the original sublists. In other words, the
        first returned sublist will have the first element from each
        of the input sublists, and the second result sublist will have
        the second element from each input sublist, etc.

        Example:
          $ [[1,2,3],['a','b','c']] \\ zip
          [[1,'a'],[2,'b'],[3,'c']]
        """
        
    zip: (argv,ls,ctx) =>
        (if argv.length != 0
            Result.err "zip does not accept parameters"
        else
            try 
                Result.wrap (List.zip ls)
            catch e
                Result.err (''+e)
        ).map_err (msg)->  ("zip: "+msg)

    help__unzip: ()->"""
        unzip

        unzip does exactly the same thing as zip. It's just an alias
        in case you forget that zip undoes itself by just calling it
        again

        Example:
          $ [[1,2,3],['a','b','c']] \\ zip
          [[1,'a'],[2,'b'],[3,'c']]
        
          $ [[1,'a'],[2,'b'],[3,'c']] \\ unzip
          [[1,2,3],['a','b','c']]
        """
     
    unzip: (argv,ls,ctx) =>
        (if argv.length != 0
            Result.err "unzip does not accept parameters"
        else
            try
                Result.wrap (List.zip ls)
            catch e
                Result.err (''+e)
        ).map_err (msg)->  ("unzip: "+msg)

    help__flatten: ()->"""
        flatten

        flatten takes a list of lists and removes one layer of
        nesting. If your data looks like a list of flat lists, and you
        want it to just be a single flat list, flatten will do
        that. It ignores elements that aren't sublists, leaving them
        alone in the data, so you can use this to get rid of unwanted
        nesting with mixed data.

        Examples:
          $ [[1,2,3],[4,5,6]] \\ flatten
          [1,2,3,4,5,6]

          $ [[[1,2],3], 4] \\ flatten
          [[1,2],3,4] 
        """
        
    flatten: (argv,ls,ctx) =>
        (if argv.length != 0
            Result.err "flatten does not accept parameters"
        else
            try
                Result.wrap (List.flatten ls)
            catch e
                Result.err (''+e)
        ).map_err (msg)->  ("flatten: "+msg)

    help__squash: ()->"""
        squash

        squash removes all levels of nesting from a nested list. No
        matter how deeply the list is nested, the returned value will
        be a flat list, which preserves the order of the elements as
        you would expect.

        Example:
          $ [[[[1],2],3],[[[4]]]] \\ squash
          [1,2,3,4]
        """
     
    squash: (argv,ls,ctx) =>
        (if argv.length != 0
            Result.err "squash does not accept parameters"
        else
            try
                Result.wrap (List.squash ls)
            catch e
                Result.err (''+e)
        ).map_err (msg)->  ("squash: "+msg)

    help__sort: ()->"""
        sort [function(a,b)]

        sort the input list according to the given comparison
        function. The comparison function should return values as
        follows:
           if a before b then return -1
           if a same as b then return 0
           if a after b then return 1

        The sort function is optional. If you use the default, it will
        sort numbers according to their value (NOT the javascript
        default of sorting them according to their alphabetical
        order), and it will sort strings alphabetically. In mixed
        data, numbers are less than strings, and everything else is
        sorted using javascript's default comparison.

        Examples:
          $ [3,31,5,22] \\ sort
          [3,5,22,31]

          $ [3,'a',{b:12},31,5,22] \\ sort
          [3, 5, 22, 31, {b: 12}, 'a']
        """
     
    sort: (argv,ls,ctx) =>
        console.log "sort"
        cmp = Utils.smartcmp
        (if argv.length > 0
            Utils.parsefunction (argv.join " "),ctx
                .map_err (e) ->  "sort: expected a comparison function, or nothing"
                .and_then (cmp) ->
                    try
                        Result.wrap (List.sort ls,cmp)
                    catch e
                        Result.err (''+e)
        else
            Result.wrap (List.sort ls,cmp)
        ).map_err (e) ->  ("sort: "  + e)

    help__uniq: ()->"""
        uniq [compare]

        uniq takes an optional comparison function and returns the
        input list with all duplicate entries removed. This works like
        the unix uniq command, which means you *have* to give it
        sorted data. You can use the same comparison function for uniq
        that you use for sort (and the default function will work in
        almost all cases, which means you can usually just skip this
        parameter entirely). If you need to wrote a comparison
        function, it should return zero if the two items are equal.

        Uniq only compares adjacent items in the list. If your list is
        not sorted so that the duplicate items are all next to each
        other, it will not work.

        Examples:
            $ [1,2,2,3,3,3,4] \\ uniq
            [1,2,3,4]

            $ [1,2,1,2,1,2,1,2] \\ uniq
            [1,2,1,2,1,2,1,2]

            The first example shows how uniq dedups the list. The
            second example shows that it doesn't work if your dups
            aren't all adjacent to each other (which can be easily
            achieved with the sort command, see 'help sort'). 
        """
        
    uniq: (argv,ls,ctx)->
        cmp = Utils.smartcmp
        (if argv.length > 0
            Utils.parsefunction (argv.join ' '),ctx
                .map_err (e)-> "expected a list"
                .and_then (proc)-> Result.wrap (List.uniq ls,proc)
        else
            Result.wrap (List.uniq ls,cmp)
        ).map_err (e)-> ("uniq: "+e)
        
    help__wrap: ()->"""
        wrap &lt;value&gt;
        
        This just turns a coffeescript expression into a result object
        that can be used to feed data through a pipeline of
        commands. This function is called implicitly when you start a
        command line out with a coffeescript expression instead of a
        command.

        These two examples are identical in their behavior internally:
        
        Examples:
          $ wrap [1,2,3]
          [1,2,3]

          $ [1,2,3]
          [1,2,3]
        """
    
    wrap: (argv,data,ctx) =>
        Utils.parsevalue (argv.join " "),ctx
            .map_err (e) ->  ("wrap: "+e)

    help__nest: ()->"""
        nest &lt;path_function&gt;

        nest works like group, except that your function should return
        a list of keys to use like a filesystem path. Each item in the
        data set will be placed into an object hierarchy so that its
        key list will locate it uniqely. This is useful for making
        tree structures.

        Example:
            $ [1,2,3,4,5] \\ nest (n) -> [
                (if n > 3 then 'large' else 'small'),
                (if n % 2 == 0 then 'even' else 'odd')]
            {
               large: {even: [4], odd:[5]},
               small: {even: [2], odd: [1,3]}
            }

        Note: If you get the message 'expected a function', ensure
        that you have any if/else statements that are used like
        expressions surrounded by parentheses. Coffeescript fails to
        parse the expression otherwise. The if statements in the
        example demonstrate how to do this. """

    nest: (argv,d,ctx) =>
        (Utils.parsefunction (argv.join " "),ctx
            .map_err (e) ->  "expected a function"
            .and_then (pathmkr) ->
                try
                    Result.wrap (List.nest d,pathmkr)
                catch e
                    Result.err (''+e))
        .map_err (e) ->
            if (''+e == 'expected a function') and (argv.join ' ').indexOf("if") != -1
                Result.err ("nest: "+e+ ' (ensure all "if" expressions are surrounded by parentheses)')
            else
                Result.err ("nest: "+e)

    help__bfs: ()->"""
        bfs &lt;func(item)&gt;

        bfs traverses a nested list or object in breadth-first
        fashion, calling the function on each element and appending
        its return value to a list (which will be in breadth-first
        order.

        Examples:
            $ [1,[4,[9,10,11],5],2,[6,7,8],3] \\ bfs (x)-> x
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

            $ {a: 1, b: [1,2,3], c: {d: 5, e: 6}} \ bfs (x,p) -> '['+(p.join ',')+']' + '=' + x
            ['[a]=1', '[b]=1,2,3', '[c,d]=5', '[c,e]=6']
        """
 
    bfs: (argv,d,ctx) =>
        (Utils.parsefunction (argv.join " "),ctx
            .map_err (e) ->  "expected a function"
            .and_then (proc) ->
                try
                    if Utils.isArray d
                        Result.wrap (List.bfs d,proc)
                    else if Utils.isObject d
                        Result.wrap (Struct.bfs d,proc)
                    else Result.wrap (proc d)
                catch e
                    Result.err (''+e))
        .map_err (e) ->  ("bfs: "+e)

    help__histogram: ()->"""
        histogram

        Compute the histogram of the data. Expects the data to be in a
        list format where each element is an instance of one of the
        bins to be counted. The result is returned as an object with
        one key for each unique element, and a count of the instances
        of that element as the value.

        Example:
            $ [1,1,1,2,3,3,3,4,4,4,4,4] \ pdf
            {1:3, 2: 1, 3: 3, 4: 5}

        """
        
    histogram: (argv,d,ctx) =>
        (try
            Result.wrap (List.histogram d)
        catch e
            Result.err (''+e))
        .map_err (e)-> ("pdf: "+e)

    help__tabulate: () -> """
        tabulate [basevalue]

        tabulate fills out a 2d table from a sparse representation of
        the table. Assuming you have an object, which has a number of
        keys whose associated values are also objects, tabulate will
        iterate through all keys and subkeys to collect all of the row
        identifiers and column identifiers. It will then generate a
        table that includes *all* rows and columns from all data
        elements, with the elements themselves populated at the
        appropriate positions. An example of using this might be to
        transform an association list representation of a network into
        a full association matrix. For example, if you have data that
        tells you when messages have passed between various hosts on a
        network, use the pipe system to work that data into an object
        with a key for each entity that has sent a message, and a
        value that's an object with a key for each entity that the
        sender has sent *to*. Then, pipe that data into tabulate, and
        it will generate a full table for you so that you can render
        it or further manipulate it in a normalized way.

        basevalue is optional, and allows you to either generate a
        list-structured table or an object-structured table. It
        defaults to object-structured.

        Example (association matrix of communicating hosts):
            $ get "http://somewhere.com/messages.json" \\
            .. group (msg)->msg.sender \\
            .. mapkeys (sender, receivers) -> List.group receivers, (msg)->msg.receiver \\
            .. tabulate

        The example will fetch a list of messages from some server,
        then group them by sender (this returns an object with a key
        for each unique sender, and a list of all messages that sender
        sent). It then iterates over the senders in that object to
        further group the messages by receiver. The object now has the
        structure obj[sender][receiver] = [list of messages]. This is
        passed to tabulate, which generates a full 2d table and puts
        the message lists in the appropriate row and column. At this
        point you could easily generate a heatmap from the data to
        show which hosts are talking most frequently, or do some other
        processing to it that takes advantage of the full table
        structure.
    """

    tabulate: (argv,data,ctx) =>
        (Utils.parsevalue argv,ctx)
            .and_then (baseval) ->
                baseval ?= {}
                try
                    rows = (key for own key of data).sort()
                    cols = {}
                    result = {}
                    for row in rows
                        for own col of data[row]
                            cols[col] = true
                    cols = (key for own key of cols).sort()
                    for row in rows
                        for col in cols
                            result[row] ?= {}
                            result[row][col] ?= baseval
                            if data[row][col]
                                result[row][col] = data[row][col]
                    Result.wrap result
                catch e
                    Result.err e
        .map_err (e)-> ("tabulate: "+e)

    help__deepmap: ()->"""
        deepmap <proc>

        Apply proc to every element of a nested data structure. The
        structure can be either a list or an object. In both cases, an
        item is considered to be a leaf when it's not the same type as
        the overall object (so anything that's not an object is a leaf
        for the object, and anything that's not an array is a leaf for
        the array version). The resulting value will mirror the
        original structure, but the values will all be replaced with
        the result of running proc on the original value in that
        place.

        Example:
            $ [[1,[2,3],4],5] \\ deepmap (n)->n*2
            [[2,[4,6],8],10]
        """

    deepmap: (argv,d,ctx) =>
        (Utils.parsefunction argv.join ' ',ctx)
            .and_then (proc) ->
                if Utils.isArray d
                    Result.wrap (List.deepmap d,proc)
                else
                    Result.wrap (Struct.deepmap d,proc)
            .map_err (e) ->  ("deepmap: "+e)
    help__cmb: () ->"""
        cmb <n> 

        Accept a list from the pipeline and generate all possible
        combinations of n items from the list. This is useful for
        situations where you want to generate a network diagram and
        you have lists of things that should be connected with each
        other. Just set n to 2 and you're done.

        This treats different orderings of the pair as different
        entities, so [2,3] is not the same as [3,2].

        Example:
            $ [1,2,3] \\ cmb 2
            [[1,2],[1,3],[2,1],[2,3],[3,1],[3,2]]
        """
    
    cmb: (argv,d,ctx) =>
        (Utils.parsevalue argv.join ' ', ctx)
            .and_then (ct) ->
                Result.wrap (List.cmb d,ct)
            .map_err (e)-> ("cmb: "+e)

    help__window: ()->"""
        window n proc

        Sliding window calculation - starting at data[0...n], call
        proc on those n elements for each element up to
        data.length-n. The result is a list of data.length-n items
        representing the result of the function call on each sublist.

        Example:
            $ [0...10] \\ window 3 (a,b,c)->a+b+c
            [3, 6, 9, 12, 15, 18, 21, 24]

        The example just sums the current three elements for every
        consecutive group of three elements in the list. The input
        list is ten elements, and the output list is seven. 
        """
        
    window: (argv,d,ctx) =>
        (Utils.parsevalue argv[0],ctx)
            .and_then (n) ->
                (Utils.parsefunction argv[1..].join ' ',ctx)
                    .and_then (proc) ->
                        Result.wrap (List.window d,n,proc)
            .map_err (e)->  ("window: "+e)

    help__intersect: ()->"""
        intersect [proc]

        intersect finds all of the elements in common between all
        items in a list of lists or objects. It treats the input as a
        set of sets and computes the intersection of all of them. The
        proc argument is optional, and can be used to specify how to
        decide which items are equal by providing a name based on the
        item. For example, if you have a set of lists of groups of
        numbers, you could specify proc to just sum the numbers in a
        group. The intersection would then be calculated based on that
        sum as the identifying property of each group.

        The result returned is an object that has keys for each
        identified item (result of calling proc), and a list of the
        items from each set that matched.

        If you have multiple items within a single set that map to the
        same identifier, you will get unexpected results. The
        colliding items will count separately toward the intersection
        goal, so you may get extra elements in the corresponding list,
        or you may get some elements that don't appear in all sets.

        Example:
            $ [[[1..3],[6],[2,3]],[[2,4],[5]],[[6],[5],[2,3,4]]] \\
            .. intersect (ls)->ls.reduce (a,b)->a+b
            {
              5: {count: 3, items: [[2, 3], [5], [5]]},
              6: {count: 4, items: [[1, 2, 3], [6], [2, 4], [6]]}
            }
                    
        In the example, note that the group that sums to 6 has four
        items even though there are only three sets involved. This
        happened because the first set has two items that sum to six
        (the [1..3] group and the [6])
        """
        
    intersect: (argv,data,ctx) =>
        proc = null
        if argv.length > 0
            proc = Utils.parsefunction argv.join ' ',ctx
        else
            proc = Utils.parsefunction '(x)->x'
        proc
            .map (p)->List.intersect data,p
            .map_err (e) ->  ("intersect: "+e)

    help__select: ()->"""
        select [list,of,keys]

        Select lets you pick only specific items out of an indexable
        object (array or struct). Provide a coffeescript formatted
        list on the command line (this will be evaluated, so it can be
        data from other sources, or even the result of a function
        call, etc). The returned data will have only the fields
        specified. If fields are specified but not present in the
        input, they will be ignored.

        Example:
            $ {a: 1,b:2, c:3} \\ select ['a','c','d']
            {a: 1, c:3}

        In the example, fields a and c are picked, but there is no d
        in the input so it is ignored. Field b is removed.
        """
        
    select: (argv, data, ctx) ->
        Utils.evalargs argv,ctx
            .and_then (args) ->
                if Utils.isArray data
                    Result.wrap (List.select data,args[0])
                else
                    Result.wrap (Struct.select data,args[0])
            .map_err (e)->("select: "+e)

    help__paths:()->"""
        paths <template>

        paths lets you select and flatten complicated objects into
        just the pieces you want. You pass it an object with the keys
        you want to end up with, and the path to get the value for
        each key from the input data, and it will run through the data
        and make an object with just the data you selected.
        
        Examples:
            $ {a: 1, {b: 2, c: {d: 55}}} \\ paths new_a: 'a', newfield: 'a.b.c.d'
            {new_a: 1, newfield: 55}
        """

    paths: (argv,data,ctx) =>
        (Utils.parsevalue (argv.join ' '),ctx)
            .and_then (pth) =>
                console.log "paths got data: ",data
                if Utils.isArray data
                    Result.wrap (List.map data, ((s) -> Struct.paths s,pth))
                else
                    Result.wrap (Struct.paths data,pth)

module.exports = BaseCommands
