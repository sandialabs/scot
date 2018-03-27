Utils = require './utils'
{Result} = require './result'

Strings =
    pat: 
        ip: /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
        hostname: /([a-zA-Z0-9_\-]\.)+[a-zA-Z0-9_\-]+/
        unixtime: /1[0-9]{9}\.[0-9]{6}/
        hms: /([0-9]{2}):([0-9]{2}):([0-9]{2})/
        timedate: /(Mon|Tue|Wed|Thu|Fri|Sat|Sun) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ([0-9]+) ([0-9]+):([0-9+):([0-9]+) ([0-9]+)/
        email: /(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/
        
    pick: (rx,str) ->
        re = new RegExp rx.source,'g'
        result = []
        match=null
        while (match=re.exec str)
            result.push match
        result
    
    words: (str)->
        console.log "Words of ",str
        w = str.replace /[^a-zA-Z]+/g,' '
        ((w.split ' ').filter (s)->s.length).map ((s)->s.toLowerCase())

    letters: (str)->
        result = {}
        for letter in str
            result[letter] ?= 0
            result[letter] += 1
        result

    nohtml: (wordlist) ->
        wordlist.filter (s)->not (s of Strings.HtmlWords)

    nocommon: (wordlist) ->
        wordlist.filter (s)->not (s of Strings.CommonWords)
        
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
                    Strings.pick re,d
                .map_err (e) ->  ("pick: "+e)

Strings.HtmlWords = 
    a: true
    abbr: true
    acronym: true
    address: true
    applet: true
    area: true
    article: true
    aside: true
    audio: true
    b: true
    base: true
    basefont: true
    bdi: true
    bdo: true
    big: true
    blockquote: true
    body: true
    br: true
    button: true
    canvas: true
    caption: true
    center: true
    cite: true
    code: true
    col: true
    colgroup: true
    datalist: true
    dd: true
    del: true
    details: true
    dfn: true
    dialog: true
    dir: true
    div: true
    dl: true
    dt: true
    em: true
    embed: true
    fieldset: true
    figcaption: true
    figure: true
    font: true
    footer: true
    form: true
    frame: true
    frameset: true
    h6: true
    head: true
    header: true
    hr: true
    html: true
    i: true
    iframe: true
    img: true
    input: true
    ins: true
    kbd: true
    keygen: true
    label: true
    legend: true
    li: true
    link: true
    main: true
    map: true
    mark: true
    menu: true
    menuitem: true
    meta: true
    meter: true
    nav: true
    noframes: true
    noscript: true
    object: true
    ol: true
    optgroup: true
    option: true
    output: true
    p: true
    param: true
    picture: true
    pre: true
    progress: true
    q: true
    rp: true
    rt: true
    ruby: true
    s: true
    samp: true
    script: true
    section: true
    select: true
    small: true
    source: true
    span: true
    strike: true
    strong: true
    style: true
    sub: true
    summary: true
    sup: true
    table: true
    tbody: true
    td: true
    textarea: true
    tfoot: true
    th: true
    thead: true
    time: true
    title: true
    tr: true
    track: true
    tt: true
    u: true
    ul: true
    var: true
    video: true
    wbr: true

Strings.CommonWords =
    the: true
    be: true
    and: true
    of: true
    a: true
    in: true
    to: true
    have: true
    to: true
    it: true
    I: true
    that: true
    for: true
    you: true
    he: true
    with: true
    on: true
    do: true
    say: true
    this: true
    they: true
    at: true
    but: true
    we: true
    his: true
    from: true
    that: true
    not: true
    by: true
    she: true
    or: true
    as: true
    what: true
    go: true
    their: true
    can: true
    who: true
    get: true
    if: true
    would: true
    her: true
    all: true
    my: true
    make: true
    about: true
    know: true
    will: true
    as: true
    up: true
    one: true
    time: true
    there: true
    year: true
    so: true
    think: true
    when: true
    which: true
    them: true
    some: true
    me: true
    people: true
    take: true
    out: true
    into: true
    just: true
    see: true
    him: true
    your: true
    come: true
    could: true
    now: true
    than: true
    like: true
    other: true
    how: true
    then: true
    its: true
    our: true
    two: true
    more: true
    these: true
    want: true
    way: true
    look: true
    first: true
    also: true
    new: true
    because: true
    day: true
    more: true
    use: true
    no: true
    man: true
    find: true
    here: true
    thing: true
    give: true
    many: true
    well: true
    
module.exports = Strings
