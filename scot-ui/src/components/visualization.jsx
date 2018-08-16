let React = require( 'react' );

let Visualization = React.createClass( {
    getInitialState: function(){
        let editor=new window.Shell.Editor();
        return {
            editor: editor,
            shell:new window.Shell.Shell( editor )
        };
    },
    keypress: function( evt ){
        return this.state.editor.keyPress( evt );
    },
    componentDidMount: function() {
        console.log( 'mounted' );
        this.state.editor.init( document.getElementById( 'revl-shell-panel' ) );
        this.state.editor.setCommandHandler( this.state.shell.doCommand.bind( this.state.shell ) );
        this.state.editor.setCompletionHandler( this.state.shell.doCompletion.bind( this.state.shell ) );
        this.state.shell.addCommands( BaseCommands );
        this.state.shell.addCommands( Viz.Barchart.commands );
        this.state.shell.addCommands( Viz.Linechart.commands );
        this.state.shell.addCommands( Viz.Dotchart.commands );
        this.state.shell.addCommands( Viz.Forcegraph.commands );
        this.state.shell.addCommands( Poly.commands );
        this.state.shell.addCommands( Http.commands );
        this.state.shell.addCommands( Nspace.commands );
        this.state.shell.addCommands( Strings.commands );
        this.state.shell.addCommands( ResultPromise.commands );
    },
    render: function() {
        console.log( 'rendering' );
        return (
            <div id="visualization" style={{position:'absolute',top:'5vh',bottom:0,right:0,left:0, height:'95vh', width:'100vw'}} > 
                <div id="revl-preview"></div>
                <div id="revl-vizbox"></div>
                <div id="revl-shell-panel" className="term" tabIndex="0" onKeyPress={this.keypress}></div>
            </div>
        );
    },
    shouldComponentUpdate: function() {
        console.log( 'should update?' );
        return true;
    }
} );

module.exports = Visualization;
