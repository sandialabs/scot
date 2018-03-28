Utils = require './utils'
{Result} = require './result'

Struct =
    bfs: (s,proc) ->
        result = []
        q = ([[k],s[k]] for own k of s)
        n=0
        while q.length > 0
            item = q.shift()
            if Utils.isObject item[1]
                [].push.apply q,([(item[0].concat [k]),item[1][k]] for k of item[1])
            else
                result.push proc item[1],item[0],n
                n = n+1
        result
       
    map: (s,proc) ->
        result = {}
        for own key,value of s
            result[key] = (proc value,key)
        result

    mapfields: (s,fields,proc) ->
        result = {}
        if !Utils.isArray fields
            fields = [fields]
        for own key,value of s
            if key in fields
                result[key]=proc value,s
            else
                result[key] = value
        result

    deepmap: (s,proc) ->
        result = {}
        for own key,value of s
            if Utils.isObject value
                result[key] = Struct.deepmap value,proc
            else
                result[key] = proc value
        result

    filter: (s,proc) ->
        result = {}
        for own key,value of s
            if proc value,key
                result[key] = value
        result

    zip: (s1,s2) ->
        result = {}
        for own key of s1
            result[key] = [s1[key],s2[key]]
        result
        
    tolist: (s)-> [key,s[key]] for own key of s

    select: (s,keys) ->
        r={}
        r[k]=s[k] for k in keys when k of s
        r

    paths: (s,paths) ->
        r={}
        getpath = (s,path) ->
            result = s
            for subpath in path
                if result
                    result = result[subpath]
                else
                    return undefined
            return result
        for own key,path of paths
            r[key] = getpath s, (path.split /[\. ]/)
        r
        
    compare: (s1,s2) ->
        similarity = 0
        for own field of s1
            if field of s2
                similarity += 1
        similarity / ((Object.keys s1).length)

    similarity: (s1, s2) ->
        prod = 0
        mag = 0
        for own field of s1
            mag += s1[field] * s1[field]
            if field of s2
                prod += s1[field] * s2[field]
        if mag < 0.01
            mag = 1
        prod / mag
        
module.exports = Struct
