Utils = require './utils'

List =
    map: (list,proc) -> list.map proc

    filter: (list,proc) -> list.filter proc

    foldl: (acc,list,proc) ->
        result = acc
        for item,n in list
            result = proc result,item,n
        result
        
    foldr: (list,acc,proc) ->
        result = acc
        for n in [(list.length-1) .. 0]
            result = proc list[n],result,n
        result

    group: (list,sep) ->
        List.foldl {},list,((groups,element) ->
            name = sep element
            groups[name] ?= []
            groups[name].push element
            groups)

    deepmap: (ls,proc) ->
        result = []
        for item in ls
            if Utils.isArray item
                result.push List.deepmap item,proc
            else
                result.push (proc item)
        result
        
    mapall: (ls,proc) ->
        result = []
        if (ls.length < 1) or !(Utils.isArray ls[0])
            return result
        for i in [0...ls[0].length]
            result.push (proc (ls.map (l)->l[i])...)
        result
        
    zip: (ls) -> List.mapall ls, (args...)->args

    flatten: (ls) -> List.foldl [], ls, (acc,val)-> acc.concat val

    squash: (ls) ->
        acc = []
        squasher = (item) ->
            if Utils.isArray item
                squasher i for i in item
            else
                acc.push item
        squasher ls
        acc

    sort: (ls, proc=Utils.smartcmp) -> ls.sort proc

    uniq: (ls, cmp=Utils.smartcmp) ->
        List.foldl [ls[0]],ls[1..],((r,item)->(if (0!=cmp item,r[r.length-1]) then r.push item); r)
        
    nest: (ls, proc) ->
        paths = ({item: item, path: proc item,n} for item,n in ls)
        #console.log "paths: "+JSON.stringify paths
        nested = {}
        for entry in paths
            current = nested
            for name in entry.path
                current[name] ?= {}
                current = current[name]
            current.$ ?= []
            current.$.push entry.item
        nested

    bfs: (ls,proc) ->
        result = []
        q=(i for i in ls)
        n=0
        while (q.length > 0)
            item = q.shift()
            if Utils.isArray item
                q.push.apply(q,item)
            else
                result.push (proc item,n)
                n = n+1
        result

    histogram: (ls,proc) ->
        p = {}
        for n in ls
            p[n]?=0
            p[n]++
        p

    tostruct: (ls) -> List.foldl {}, ls, ((acc,l)->acc[l[0]]=l[1]; acc)
    
    cmb: (ls,n) ->
        # Generate all unique n-ary tuples from elements of ls
        console.log "cmb #{JSON.stringify ls},#{n}"
        result=[]
        if n > ls.length
            throw "Can't take #{n} from list of length #{ls.length}"
        if n == 1
            r = ls.map (e)->[e]
            return r
        for i in [0..ls.length-n]
            r = List.cmb ls[i+1..],n-1
            r.forEach (l)->l.unshift ls[i]
            result = result.concat r
        result    

    window: (ls,n,proc) ->
        # slide a window of n elements down the list and call proc on
        # each position. Proc must accept n arguments.
        if ls.length < n
            throw "Window of #{n} too large for list of #{ls.length} elements"
        (proc.apply {},ls[i...i+n]) for i in [0..ls.length-n]

    # Take a list of lists and optionally a function, and generate the
    # set intersection of all of the lists based on what the function
    # returns. The function provides a key so that complex objects can
    # be intersected based on arbitrary criteria. The result will be a
    # list of objects, each of which has they key from the function as
    # well as the original data from all of the elements that shared
    # that key, but only for keys that appeared in *all* sublists. It
    # is important that the key returned by the proc be unique
    # *within* each sublist.
    intersect: (ls,proc=(x)->x) ->
        set = {}
        listcount=0
        for own g_index,group of ls
            listcount++
            for own index,value of group
                key = proc value,index
                set[key] ?=
                    count: 0
                    items: []
                set[key].count++
                set[key].items.push value
        for k in Object.keys set
            if set[k].count < listcount
                delete set[k]
        set
        for k in Object.keys set
            if set[k].count < listcount
                delete set[k]
        set

    select: (data,indexes) -> data[index] for index in indexes when index of data
        
List.fold = List.foldr
List.unzip = List.zip

module.exports = List

if (typeof window)=='undefined'
    console.log (List.cmb [1,2,3,4],2)
