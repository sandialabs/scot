'use strict';

var React        = require('react'),
    ActionButton = require('./ActionButton.react'),
    ButtonsSpace,
    Component;

ButtonsSpace = React.createClass({

	displayName: 'PopupFooterButtons',

	getInitialProps: function () {
		return {
			buttons     : null,
			className   : null,
			onOk        : null,
			onClose     : null,
			buttonClick : null,
			btnClass    : null,
			href        : null
		};
	},

	onOk: function () {
		if (this.props.onOk) {
			return this.props.onOk();
		}
	},

	onClose: function () {
		if (this.props.onClose) {
			return this.props.onClose();
		}
	},

	buttonClick: function (action) {
		if (this.props.buttonClick) {
			return this.props.buttonClick(action);
		}
	},

	wildClass: function (className, base) {
		if (!className) {
			return null;
		}

		if (this.props.wildClasses) {
			return className;
		}

		var finalClass = [],
		    classNames = className.split(' ');

		classNames.forEach(function (className) {
			finalClass.push(base + '--' + className);
		});

		return finalClass.join(' ');
	},

	render: function () {
		if (!this.props.buttons) {
			return null;
		}

		var i, btns = [], btn, className, url;

		for (i = 0; i < this.props.buttons.length; i++) {
			btn = this.props.buttons[i];
			url = (btn.url) ? btn.url : null;

			if (typeof btn === 'string') {
				if (btn === 'ok') {
					btns.push(<ActionButton className={this.props.btnClass + ' ' + this.props.btnClass + '--ok'} key={i} onClick={this.onOk}>{this.props.defaultOk}</ActionButton>);
				} else if (btn === 'cancel') {
					btns.push(<ActionButton className={this.props.btnClass + ' ' + this.props.btnClass + '--cancel'} key={i} onClick={this.onClose}>{this.props.defaultCancel}</ActionButton>);
				}
			} else {
				className = this.props.btnClass + ' ' + this.wildClass(btn.className, this.props.btnClass);
				btns.push(<ActionButton className={className} key={i} url={url} onClick={this.buttonClick.bind(this, btn.action)}>{btn.text}</ActionButton>);
			}
		}

		return (
			<div className={this.props.className}>
				{btns}
			</div>
		);
	}

});

Component = React.createClass({

	displayName: 'PopupFooter',

	getInitialProps: function () {
		return {
			buttons: null,
			className: null,
			wildClasses: false,
			btnClass: null,
			defaultOk: null,
			defaultCancel: null,
			buttonClick: null,
			onOk: null,
			onClose: null
		};
	},

	render: function () {
		if (this.props.buttons) {
			return (
				<footer className={this.props.className}>
					<ButtonsSpace
						buttonClick={this.props.buttonClick}
						onOk={this.props.onOk}
						onClose={this.props.onClose}
						className={this.props.className + '__left-space'}
						wildClasses={this.props.wildClasses}
						btnClass={this.props.btnClass}
						defaultOk={this.props.defaultOk}
						defaultCancel={this.props.defaultCancel}
						buttons={this.props.buttons.left} />

					<ButtonsSpace
						buttonClick={this.props.buttonClick}
						onOk={this.props.onOk}
						onClose={this.props.onClose}
						className={this.props.className + '__right-space'}
						wildClasses={this.props.wildClasses}
						btnClass={this.props.btnClass}
						defaultOk={this.props.defaultOk}
						defaultCancel={this.props.defaultCancel}
						buttons={this.props.buttons.right} />
				</footer>
			);
		}

		return null;
	}

});

module.exports = Component;