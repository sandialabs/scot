
class History
    constructor: () ->
        @stack = JSON.parse localStorage.getItem 'history'
        @stack ?= []
        @active = ""

    setActive: (cmd) =>
        @active = cmd

    acceptActive: () =>
        if @active != @stack[0]
            @stack.unshift @active+""
            localStorage.setItem 'history',JSON.stringify @stack
        @active = ""

    changeIndex: (old,delta) =>
        console.log "history change index: old="+old+", delta="+delta
        result = old+delta
        if result < 0
            result = -1
        if result >= @stack.length
            result = @stack.length-1
        result
        
    clear: () =>
        @stack = []
        localStorage.setItem 'history','[]'
        
    get: (index) =>
        switch
            when @stack.length == 0 && index != -1
                ""
            when index >= @stack.length
                ""
            when index < 0
                @active
            else
                @stack[index]

    all: () =>
        @stack

module.exports = History
