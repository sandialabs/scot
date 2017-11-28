Utils = require './utils'
{Result} = require './result'

Strings =
    pat: 
        ip: /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
        hostname: /([a-zA-Z0-9_\-]\.)+[a-zA-Z0-9_\-]+/
        unixtime: /1[0-9]{9}\.[0-9]{6}/
        hms: /([0-9]{2}):([0-9]{2}):([0-9]{2})/
        timedate: /(Mon|Tue|Wed|Thu|Fri|Sat|Sun) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ([0-9]+) ([0-9]+):([0-9+):([0-9]+) ([0-9]+)/
        email: /[^ ]+@([a-zA-Z0-9_\-]+\.)+[a-zA-Z0-9_\-]+/
        
    pick: (rx,str) ->
        re = new RegExp rx.source,'g'
        result = []
        match=null
        while (match=re.exec str)
            result.push match
        result
    commands:
        help__pick: ()->"""
            pick <regex>

            Scan the piped in string for instances of regex, and
            return a list of all matches. Each element of the list
            will be the full match object from the regex match, so you
            can access the index and the input from each match.

            This function is also available inside your pipeline
            functions under the name Strings.pick. If you call it
            directly, pass the regular expression as the first
            argument and the string to pick from as the second
            argument

            Example:
                $ "abcdefghi" \\ pick /[a-z]{3}
                [["abc",index:0,input:"abcdefghi"],
                 ["def",index:3,input:"abcdefghi"],
                 ["ghi",index:6,input:"abcdefghi"]]

                $ ["abc","def","ghi"] \\ (s)->Strings.pick /[a-z]{2}/, s
                [["ab",index:0,input:"abc"],["de",index:0,input:"def"],["gh",index:0,input"ghi"]]
            """
        pick: (argv,d,ctx) ->
            (Utils.parsevalue argv[0],ctx)
                .map (re) ->
                    if not re instanceof RegExp
                        return Result.err "Please supply a regular expression on the command line"
                    Result.wrap Strings.pick re,d
                .map_err (e) ->  ("pick: "+e)

module.exports = Strings
