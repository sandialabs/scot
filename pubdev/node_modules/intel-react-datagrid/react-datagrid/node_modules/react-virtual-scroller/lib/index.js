'use strict';

var _interopRequireDefault = function (obj) { return obj && obj.__esModule ? obj : { 'default': obj }; };

var _classCallCheck = function (instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _inherits = function (subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) subClass.__proto__ = superClass; };

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

Object.defineProperty(exports, '__esModule', {
	value: true
});

var _Component2 = require('react-class');

var _Component3 = _interopRequireDefault(_Component2);

'use strict';

var React = require('react');
var LoadMask = require('react-load-mask');
var assign = require('object-assign');
var DragHelper = require('drag-helper');
var normalize = require('react-style-normalizer');
var hasTouch = require('has-touch');

var preventDefault = function preventDefault(event) {
	return event && event.preventDefault();
};
var signum = function signum(x) {
	return x < 0 ? -1 : 1;
};
var emptyFn = function emptyFn() {};
var ABS = Math.abs;

var LoadMaskFactory = React.createFactory(LoadMask);

var horizontalScrollbarStyle = {};

var IS_MAC = global && global.navigator && global.navigator.appVersion && global.navigator.appVersion.indexOf('Mac') != -1;
var IS_FIREFOX = global && global.navigator && global.navigator.userAgent && !! ~global.navigator.userAgent.toLowerCase().indexOf('firefox');

if (IS_MAC) {
	horizontalScrollbarStyle.position = 'absolute';
	horizontalScrollbarStyle.height = 20;
}

var PT = React.PropTypes;
var DISPLAY_NAME = 'Scroller';

var ON_OVERFLOW_NAMES = {
	vertical: 'onVerticalScrollOverflow',
	horizontal: 'onHorizontalScrollOverflow'
};

var ON_SCROLL_NAMES = {
	vertical: 'onVerticalScroll',
	horizontal: 'onHorizontalScroll'
};

/**
 * Called on scroll by mouse wheel
 */
var syncScrollbar = function syncScrollbar(orientation) {

	return function (scrollPos, event) {

		var domNode = orientation == 'horizontal' ? this.getHorizontalScrollbarNode() : this.getVerticalScrollbarNode();
		var scrollPosName = orientation == 'horizontal' ? 'scrollLeft' : 'scrollTop';
		var overflowCallback;

		domNode[scrollPosName] = scrollPos;

		var newScrollPos = domNode[scrollPosName];

		if (newScrollPos != scrollPos) {} else {
			preventDefault(event);
		}
	};
};

var syncHorizontalScrollbar = syncScrollbar('horizontal');
var syncVerticalScrollbar = syncScrollbar('vertical');

var scrollAt = function scrollAt(orientation) {
	var syncFn = orientation == 'horizontal' ? syncHorizontalScrollbar : syncVerticalScrollbar;

	return function (scrollPos, event) {
		// this.mouseWheelScroll = true

		syncFn.call(this, Math.round(scrollPos), event);
	};
};

var onScroll = function onScroll(orientation) {

	var clientHeightNames = {
		vertical: 'clientHeight',
		horizontal: 'clientWidth'
	};

	var scrollHeightNames = {
		vertical: 'scrollHeight',
		horizontal: 'scrollWidth'
	};

	return function (event) {

		var scrollPosName = orientation == 'horizontal' ? 'scrollLeft' : 'scrollTop';
		var target = event.target;
		var scrollPos = target[scrollPosName];

		var onScroll = this.props[ON_SCROLL_NAMES[orientation]];
		var onOverflow = this.props[ON_OVERFLOW_NAMES[orientation]];

		// if (!this.mouseWheelScroll && onOverflow){
		if (onOverflow) {
			if (scrollPos == 0) {
				onOverflow(-1, scrollPos);
			} else if (scrollPos + target[clientHeightNames[orientation]] >= target[scrollHeightNames[orientation]]) {
				onOverflow(1, scrollPos);
			}
		}

		;(onScroll || emptyFn)(scrollPos);
	};
};

/**
 * The scroller can have a load mask (loadMask prop is true by default),
 * you just need to specify loading=true to see it in action
 *
 * <Scroller loading={true} />
 *
 * If you don't want a load mask, specify
 *
 * <Scroller loadMask={false} />
 *
 * Or if you want to customize the loadMask factory, specify
 *
 * function mask(props) { return aMaskFactory(props) }
 * <Scroller loading={true} loadMask={mask}
 *
 */

var Scroller = (function (_Component) {
	function Scroller() {
		_classCallCheck(this, Scroller);

		if (_Component != null) {
			_Component.apply(this, arguments);
		}
	}

	_inherits(Scroller, _Component);

	_createClass(Scroller, [{
		key: 'render',
		value: function render() {
			var props = this.p = this.prepareProps(this.props);

			var loadMask = this.renderLoadMask(props);
			var horizontalScrollbar = this.renderHorizontalScrollbar(props);
			var verticalScrollbar = this.renderVerticalScrollbar(props);

			var events = {};

			if (!hasTouch) {
				events.onWheel = this.handleWheel;
			} else {
				events.onTouchStart = this.handleTouchStart;
			}

			//extra div needed for SAFARI V SCROLL
			//maxWidth needed for FF - see
			//http://stackoverflow.com/questions/27424831/firefox-flexbox-overflow
			//http://stackoverflow.com/questions/27472595/firefox-34-ignoring-max-width-for-flexbox
			var content = React.createElement('div', { className: 'z-content-wrapper-fix', style: { maxWidth: 'calc(100% - ' + props.scrollbarSize + 'px)' },
				children: props.children });

			var renderProps = this.prepareRenderProps(props);

			return React.createElement(
				'div',
				renderProps,
				loadMask,
				React.createElement(
					'div',
					_extends({ className: 'z-content-wrapper' }, events),
					content,
					verticalScrollbar
				),
				horizontalScrollbar
			);
		}
	}, {
		key: 'prepareRenderProps',
		value: function prepareRenderProps(props) {
			var renderProps = assign({}, props);

			delete renderProps.height;
			delete renderProps.width;

			return renderProps;
		}
	}, {
		key: 'handleTouchStart',
		value: function handleTouchStart(event) {

			var props = this.props;
			var scroll = {
				top: props.scrollTop,
				left: props.scrollLeft
			};

			var newScrollPos;
			var side;

			DragHelper(event, {
				scope: this,
				onDrag: function onDrag(event, config) {
					if (config.diff.top == 0 && config.diff.left == 0) {
						return;
					}

					if (!side) {
						side = ABS(config.diff.top) > ABS(config.diff.left) ? 'top' : 'left';
					}

					var diff = config.diff[side];

					newScrollPos = scroll[side] - diff;

					if (side == 'top') {
						this.verticalScrollAt(newScrollPos, event);
					} else {
						this.horizontalScrollAt(newScrollPos, event);
					}
				}
			});

			event.stopPropagation();
			preventDefault(event);
		}
	}, {
		key: 'handleWheel',
		value: function handleWheel(event) {

			var props = this.props;
			// var normalizedEvent = normalizeWheel(event)

			var virtual = props.virtualRendering;
			var horizontal = event.shiftKey;
			var scrollStep = props.scrollStep;
			var minScrollStep = props.minScrollStep;

			var scrollTop = props.scrollTop;
			var scrollLeft = props.scrollLeft;

			// var delta = normalizedEvent.pixelY
			var delta = event.deltaY;

			if (horizontal) {
				// delta = delta || normalizedEvent.pixelX
				delta = delta || event.deltaX;

				minScrollStep = props.minHorizontalScrollStep || minScrollStep;
			} else {
				minScrollStep = props.minVerticalScrollStep || minScrollStep;
			}

			if (typeof props.interceptWheelScroll == 'function') {
				delta = props.interceptWheelScroll(delta, normalizedEvent, event);
			} else if (minScrollStep) {
				if (ABS(delta) < minScrollStep) {
					delta = signum(delta) * minScrollStep;
				}
			}

			if (horizontal) {
				this.horizontalScrollAt(scrollLeft + delta, event);

				props.preventDefaultHorizontal && preventDefault(event);
			} else {
				this.verticalScrollAt(scrollTop + delta, event);

				props.preventDefaultVertical && preventDefault(event);
			}
		}
	}, {
		key: 'componentWillReceiveProps',
		value: function componentWillReceiveProps() {
			setTimeout(this.fixHorizontalScrollbar, 0);
		}
	}, {
		key: 'componentDidMount',
		value: function componentDidMount() {
			this.fixHorizontalScrollbar();(this.props.onMount || emptyFn)(this);

			setTimeout((function () {
				this.fixHorizontalScrollbar();
			}).bind(this), 0);
		}
	}, {
		key: 'fixHorizontalScrollbar',
		value: function fixHorizontalScrollbar() {
			this.horizontalScrollerNode = this.horizontalScrollerNode || React.findDOMNode(this).querySelector('.z-horizontal-scroller');

			var dom = this.horizontalScrollerNode;

			if (dom) {
				var height = dom.style.height;

				dom.style.height = height == '0.2px' ? '0.1px' : '0.2px';
			}
		}
	}, {
		key: 'getVerticalScrollbarNode',
		value: function getVerticalScrollbarNode() {
			return this.verticalScrollbarNode = this.verticalScrollbarNode || React.findDOMNode(this).querySelector('.ref-verticalScrollbar');
		}
	}, {
		key: 'getHorizontalScrollbarNode',
		value: function getHorizontalScrollbarNode() {
			return this.horizontalScrollbarNode = this.horizontalScrollbarNode || React.findDOMNode(this).querySelector('.ref-horizontalScrollbar');
		}
	}, {
		key: 'componentWillUnmount',
		value: function componentWillUnmount() {
			delete this.horizontalScrollerNode;
			delete this.horizontalScrollbarNode;
			delete this.verticalScrollbarNode;
		}
	}, {
		key: 'renderVerticalScrollbar',

		////////////////////////////////////////////////
		//
		// RENDER METHODS
		//
		////////////////////////////////////////////////
		value: function renderVerticalScrollbar(props) {
			var height = props.scrollHeight;
			var verticalScrollbarStyle = {
				width: props.scrollbarSize
			};

			var onScroll = this.onVerticalScroll;

			return React.createElement(
				'div',
				{ className: 'z-vertical-scrollbar', style: verticalScrollbarStyle },
				React.createElement(
					'div',
					{
						className: 'ref-verticalScrollbar',
						onScroll: onScroll,
						style: { overflow: 'auto', width: '100%', height: '100%' }
					},
					React.createElement('div', { className: 'z-vertical-scroller', style: { height: height } })
				)
			);
		}
	}, {
		key: 'renderHorizontalScrollbar',
		value: function renderHorizontalScrollbar(props) {
			var scrollbar;
			var onScroll = this.onHorizontalScroll;
			var style = horizontalScrollbarStyle;
			var minWidth = props.scrollWidth;

			var scroller = React.createElement('div', { xref: 'horizontalScroller', className: 'z-horizontal-scroller', style: { width: minWidth } });

			if (IS_MAC) {
				//needed for mac safari
				scrollbar = React.createElement(
					'div',
					{
						style: style,
						className: 'z-horizontal-scrollbar mac-fix'
					},
					React.createElement(
						'div',
						{
							onScroll: onScroll,
							className: 'ref-horizontalScrollbar z-horizontal-scrollbar-fix'
						},
						scroller
					)
				);
			} else {
				scrollbar = React.createElement(
					'div',
					{
						style: style,
						className: 'ref-horizontalScrollbar z-horizontal-scrollbar',
						onScroll: onScroll
					},
					scroller
				);
			}

			return scrollbar;
		}
	}, {
		key: 'renderLoadMask',
		value: function renderLoadMask(props) {
			if (props.loadMask) {
				var loadMaskProps = assign({ visible: props.loading }, props.loadMaskProps);

				var defaultFactory = LoadMaskFactory;
				var factory = typeof props.loadMask == 'function' ? props.loadMask : defaultFactory;

				var mask = factory(loadMaskProps);

				if (mask === undefined) {
					//allow the specified factory to just modify props
					//and then leave the rendering to the defaultFactory
					mask = defaultFactory(loadMaskProps);
				}

				return mask;
			}
		}
	}, {
		key: 'prepareProps',

		////////////////////////////////////////////////
		//
		// PREPARE PROPS METHODS
		//
		////////////////////////////////////////////////
		value: function prepareProps(thisProps) {
			var props = assign({}, thisProps);

			props.className = this.prepareClassName(props);
			props.style = this.prepareStyle(props);

			return props;
		}
	}, {
		key: 'prepareStyle',
		value: function prepareStyle(props) {
			var style = assign({}, props.style);

			if (props.height != null) {
				style.height = props.height;
			}

			if (props.width != null) {
				style.width = props.width;
			}

			if (props.normalizeStyles) {
				style = normalize(style);
			}

			return style;
		}
	}, {
		key: 'prepareClassName',
		value: function prepareClassName(props) {
			var className = props.className || '';

			if (Scroller.className) {
				className += ' ' + Scroller.className;
			}

			return className;
		}
	}]);

	return Scroller;
})(_Component3['default']);

Scroller.className = 'z-scroller';
Scroller.displayName = DISPLAY_NAME;

assign(Scroller.prototype, {
	onVerticalScroll: onScroll('vertical'),
	onHorizontalScroll: onScroll('horizontal'),

	verticalScrollAt: scrollAt('vertical'),
	horizontalScrollAt: scrollAt('horizontal'),

	syncHorizontalScrollbar: syncHorizontalScrollbar,
	syncVerticalScrollbar: syncVerticalScrollbar
});

Scroller.propTypes = {
	loadMask: PT.oneOfType([PT.bool, PT.func]),

	loading: PT.bool,
	normalizeStyles: PT.bool,

	scrollTop: PT.number,
	scrollLeft: PT.number,

	scrollWidth: PT.number.isRequired,
	scrollHeight: PT.number.isRequired,

	height: PT.number,
	width: PT.number,

	minScrollStep: PT.number,
	minHorizontalScrollStep: PT.number,
	minVerticalScrollStep: PT.number,

	virtualRendering: PT.oneOf([true]),

	preventDefaultVertical: PT.bool,
	preventDefaultHorizontal: PT.bool
}, Scroller.defaultProps = {
	'data-display-name': DISPLAY_NAME,
	loadMask: true,

	virtualRendering: true, //FOR NOW, only true is supported
	scrollbarSize: 20,

	scrollTop: 0,
	scrollLeft: 0,

	minScrollStep: 10,

	minHorizontalScrollStep: IS_FIREFOX ? 40 : 1,

	//since FF goes back in browser history on scroll too soon
	//chrome and others also do this, but the normal preventDefault in syncScrollbar fn prevents this
	preventDefaultHorizontal: IS_FIREFOX
};

exports['default'] = Scroller;
module.exports = exports['default'];

// overflowCallback = this.props[ON_OVERFLOW_NAMES[orientation]]
// overflowCallback && overflowCallback(signum(scrollPos), newScrollPos)
// raf(function(){
//     this.mouseWheelScroll = false
// }.bind(this))