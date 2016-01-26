'use strict';

var React = require('react'),
    Component;

Component = React.createClass({

	displayName: 'PopupAction',

	propTypes: {
		children: React.PropTypes.node.isRequired
	},

	getInitialProps: function () {
		return {
			onClick   : function () {},
			className : 'btn',
			url       : null
		};
	},

	handleClick: function () {
		return this.props.onClick();
	},

	render: function () {
		var className = this.props.className, url = false;
		
		if (this.props.url) {
			if (this.props.url !== '#') {
				url = true;
			}
			
			if (!url) {
				return (<a target="_blank" className={className}>{this.props.children}</a>);
			}
			
			return (<a href={this.props.url} target="_blank" className={className}>{this.props.children}</a>);
		}

		return (
			<button onClick={this.handleClick} className={className}>
				{this.props.children}
			</button>
		);
	}

});

module.exports = Component;