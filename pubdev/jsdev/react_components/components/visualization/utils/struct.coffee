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
        
    tolist: (s)-> [key,s[key]] for own key of s

    select: (s,keys) ->
        r={}
        r[k]=s[k] for k in keys when k of s
        r
        
module.exports = Struct
