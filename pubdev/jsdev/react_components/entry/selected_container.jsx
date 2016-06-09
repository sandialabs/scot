var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    getInitialState: function() {
        var scrollHeight = '100%';
        var scrollWidth = '100%';
        return {
            width: scrollWidth,
            height: scrollHeight,
        }
    },
    handleResize: function(){
        var scrollHeight = this.state.height;
        var scrollWidth = this.state.width;
        if ($('.old-list-view')) {
            scrollHeight = $(window).height() - $('.old-list-view').height() - $('#header').height() - 90
        } else {
            scrollHeight = $(window).height() - $('#header').height() - 90
        }
        if ($('#list-view')) {
            scrollWidth  = $(window).width()  - ($('#list-view').width() + 60)
        }
        this.setState({width:scrollWidth,height:scrollHeight})
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
            datarows.push(<SelectedHeader windowHeight={this.state.height} key={this.props.ids[i]} id={this.props.ids[i]} type={this.props.type} toggleEventDisplay={this.props.viewEvent} taskid={this.props.taskid}/>); 
        }
        return (
            <div className="entry-container" style={{width: this.state.width,position: 'relative'}}> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
