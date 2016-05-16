var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    reloadItem: function(){
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = $(window).width()  - $('.eventwidth').width()
        $('.entry-wrapper-main').each(function(key,value){
            $(value).css('height', scrollHeight)
            $(value).css('width',  '100%')
        })
    },
    render: function() {
        setTimeout(function(){this.reloadItem()}.bind(this),100)
        $(window).resize(function(){
            this.reloadItem()
        }.bind(this))
        var datarows = [];
        for (i=0; i < this.props.ids.length; i++) { 
            datarows.push(<SelectedHeader windowHeight={this.props.height} key={this.props.ids[i]} id={this.props.ids[i]} type={this.props.type} toggleEventDisplay={this.props.viewEvent} taskid={this.props.taskid}/>); 
        }
        return (
            <div className="entry-container" style={{width: '100%',position: 'relative'}}> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
