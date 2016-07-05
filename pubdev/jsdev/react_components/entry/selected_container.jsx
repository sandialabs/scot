var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    getInitialState: function() {
        var scrollWidth = '100%';
        return {
            width: scrollWidth,
        }
    },
    handleResize: function(){
        var scrollWidth = this.state.width;
        if ($('#list-view')[0]) {
            scrollWidth  = $(window).width()  - ($('#list-view').width() + 60)
            scrollWidth = scrollWidth + 'px'
        }
        this.setState({width:scrollWidth})
    },
    componentDidMount: function() {
        this.handleResize();
        window.addEventListener('resize',this.handleResize);
        $("#list-view").resize(this.handleResize);
    },
    componentWillUnmount: function() {
        window.removeEventListener('resize', this.handleResize);
    },
    render: function() {
        var datarows = [];
        for (i=0; i < this.props.ids.length; i++) { 
            datarows.push(<SelectedHeader key={this.props.ids[i]} id={this.props.ids[i]} type={this.props.type} toggleEventDisplay={this.props.viewEvent} taskid={this.props.taskid}/>); 
        }
        var width = this.state.width;
        return (
            <div className="entry-container" style={{width: width,position: 'relative'}}> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
