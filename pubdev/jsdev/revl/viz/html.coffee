{Result} = require '../utils/result'

class HtmlViewer
    @commands =
        help__html: () ->"""
            html

            Open the string from the command line as the body of a new
            window in the browser. When you want to see what rendered
            content looks like, use this.
            
            Examples:
                $ alertgroup limit:1,sort:{'id':-1} \ into (a)->a[0].body \ html

            The example will pull the body out of the most recent
            alertgroup and display it as html in a new browser window.
            """
            
        html: (argv,d) ->
            open().document.body.innerHTML = d
            Result.wrap d

           
module.exports = HtmlViewer
