'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _get = function get(_x, _x2, _x3) { var _again = true; _function: while (_again) { var object = _x, property = _x2, receiver = _x3; _again = false; if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { _x = parent; _x2 = property; _x3 = receiver; _again = true; desc = parent = undefined; continue _function; } } else if ('value' in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } } };

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

// Used to cancel events.
var preventDefault = function preventDefault(e) {
  return e.preventDefault();
};

var Pagination = (function (_Component) {
  _inherits(Pagination, _Component);

  function Pagination() {
    _classCallCheck(this, Pagination);

    _get(Object.getPrototypeOf(Pagination.prototype), 'constructor', this).apply(this, arguments);
  }

  _createClass(Pagination, [{
    key: 'shouldComponentUpdate',
    value: function shouldComponentUpdate(nextProps) {
      var props = this.props;

      return props.totalPages !== nextProps.totalPages || props.currentPage !== nextProps.currentPage || props.showPages !== nextProps.showPages;
    }
  }, {
    key: 'onChangePage',
    value: function onChangePage(pageNumber, event) {
      event.preventDefault();
      this.props.onChangePage(pageNumber);
    }
  }, {
    key: 'render',
    value: function render() {
      var _props = this.props;
      var totalPages = _props.totalPages;
      var showPages = _props.showPages;
      var currentPage = _props.currentPage;

      if (totalPages === 0) {
        return null;
      }

      var diff = Math.floor(showPages / 2),
          start = Math.max(currentPage - diff, 0),
          end = Math.min(start + showPages, totalPages);

      if (totalPages >= showPages && end >= totalPages) {
        start = totalPages - showPages;
      }

      var buttons = [],
          btnEvent,
          isCurrent;
      for (var i = start; i < end; i++) {
        isCurrent = currentPage === i;
        // If the button is for the current page then disable the event.
        if (isCurrent) {
          btnEvent = preventDefault;
        } else {
          btnEvent = this.onChangePage.bind(this, i);
        }
        buttons.push(_react2['default'].createElement(
          'li',
          { key: i, className: isCurrent ? 'active' : null },
          _react2['default'].createElement(
            'a',
            { role: 'button', href: '#', onClick: btnEvent, tabIndex: '0' },
            _react2['default'].createElement(
              'span',
              null,
              i + 1
            ),
            isCurrent ? _react2['default'].createElement(
              'span',
              { className: 'sr-only' },
              '(current)'
            ) : null
          )
        ));
      }

      // First and Prev button handlers and class.
      var firstHandler = preventDefault;
      var prevHandler = preventDefault;
      var isNotFirst = currentPage > 0;
      if (isNotFirst) {
        firstHandler = this.onChangePage.bind(this, 0);
        prevHandler = this.onChangePage.bind(this, currentPage - 1);
      }

      // Next and Last button handlers and class.
      var nextHandler = preventDefault;
      var lastHandler = preventDefault;
      var isNotLast = currentPage < totalPages - 1;
      if (isNotLast) {
        nextHandler = this.onChangePage.bind(this, currentPage + 1);
        lastHandler = this.onChangePage.bind(this, totalPages - 1);
      }

      buttons = [_react2['default'].createElement(
        'li',
        { key: 'first', className: !isNotFirst ? 'disabled' : null },
        _react2['default'].createElement(
          'a',
          { role: 'button', href: '#', tabIndex: '0',
            onClick: firstHandler,
            'aria-disabled': !isNotFirst,
            'aria-label': 'First' },
          _react2['default'].createElement('span', { className: 'fa fa-angle-double-left', 'aria-hidden': 'true' })
        )
      ), _react2['default'].createElement(
        'li',
        { key: 'prev', className: !isNotFirst ? 'disabled' : null },
        _react2['default'].createElement(
          'a',
          { role: 'button', href: '#', tabIndex: '0',
            onClick: prevHandler,
            'aria-disabled': !isNotFirst,
            'aria-label': 'Previous' },
          _react2['default'].createElement('span', { className: 'fa fa-angle-left', 'aria-hidden': 'true' })
        )
      )].concat(buttons);

      buttons = buttons.concat([_react2['default'].createElement(
        'li',
        { key: 'next', className: !isNotLast ? 'disabled' : null },
        _react2['default'].createElement(
          'a',
          { role: 'button', href: '#', tabIndex: '0',
            onClick: nextHandler,
            'aria-disabled': !isNotLast,
            'aria-label': 'Next' },
          _react2['default'].createElement('span', { className: 'fa fa-angle-right', 'aria-hidden': 'true' })
        )
      ), _react2['default'].createElement(
        'li',
        { key: 'last', className: !isNotLast ? 'disabled' : null },
        _react2['default'].createElement(
          'a',
          { role: 'button', href: '#', tabIndex: '0',
            onClick: lastHandler,
            'aria-disabled': !isNotLast,
            'aria-label': 'Last' },
          _react2['default'].createElement('span', { className: 'fa fa-angle-double-right', 'aria-hidden': 'true' })
        )
      )]);

      return _react2['default'].createElement(
        'ul',
        { className: this.props.className, 'aria-label': 'Pagination' },
        buttons
      );
    }
  }], [{
    key: 'defaultProps',
    value: {
      showPages: 5
    },
    enumerable: true
  }, {
    key: 'propTypes',
    value: {
      onChangePage: _react.PropTypes.func.isRequired,
      totalPages: _react.PropTypes.number.isRequired,
      currentPage: _react.PropTypes.number.isRequired,
      showPages: _react.PropTypes.number
    },
    enumerable: true
  }]);

  return Pagination;
})(_react.Component);

exports['default'] = Pagination;
module.exports = exports['default'];