'use strict';

var React = require('react'),
    Component;

Component = React.createClass({

	displayName: 'PopupHeader',

	getInitialProps: function () {
		return {
			title:     null,
			className: null
		};
	},

	render: function () {
		if (this.props.title) {
			return (
				<header className={this.props.className}>
					<h1 className={this.props.className + '__title'}>{this.props.title}</h1>
				</header>
			);
		}

		return null;
	}

});

module.exports = Component;