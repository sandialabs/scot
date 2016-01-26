'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _get = function get(_x, _x2, _x3) { var _again = true; _function: while (_again) { var object = _x, property = _x2, receiver = _x3; _again = false; if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { _x = parent; _x2 = property; _x3 = receiver; _again = true; desc = parent = undefined; continue _function; } } else if ('value' in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } } };

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

var simpleGet = function simpleGet(key) {
  return function (data) {
    return data[key];
  };
};
var keyGetter = function keyGetter(keys) {
  return function (data) {
    return keys.map(function (key) {
      return data[key];
    });
  };
};

var isEmpty = function isEmpty(value) {
  return value == null || value === '';
};

var getCellValue = function getCellValue(_ref, row) {
  var prop = _ref.prop;
  var defaultContent = _ref.defaultContent;
  var render = _ref.render;
  return(
    // Return `defaultContent` if the value is empty.
    !isEmpty(prop) && isEmpty(row[prop]) ? defaultContent :
    // Use the render function for the value.
    render ? render(row[prop], row) :
    // Otherwise just return the value.
    row[prop]
  );
};

var getCellClass = function getCellClass(_ref2, row) {
  var prop = _ref2.prop;
  var className = _ref2.className;
  return !isEmpty(prop) && isEmpty(row[prop]) ? 'empty-cell' : typeof className == 'function' ? className(row[prop], row) : className;
};

function buildSortProps(col, sortBy, onSort) {
  var order = sortBy.prop === col.prop ? sortBy.order : 'none';
  var nextOrder = order === 'ascending' ? 'descending' : 'ascending';
  var sortEvent = onSort.bind(null, { prop: col.prop, order: nextOrder });

  return {
    'onClick': sortEvent,
    // Fire the sort event on enter.
    'onKeyDown': function onKeyDown(e) {
      if (e.keyCode === 13) sortEvent();
    },
    // Prevents selection with mouse.
    'onMouseDown': function onMouseDown(e) {
      return e.preventDefault();
    },
    'tabIndex': 0,
    'aria-sort': order,
    'aria-label': col.title + ': activate to sort column ' + nextOrder
  };
}

var Table = (function (_Component) {
  _inherits(Table, _Component);

  function Table(props) {
    _classCallCheck(this, Table);

    _get(Object.getPrototypeOf(Table.prototype), 'constructor', this).call(this, props);
    this._headers = [];
  }

  _createClass(Table, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      // If no width was specified, then set the width that the browser applied
      // initially to avoid recalculating width between pages.
      this._headers.forEach(function (header) {
        var thDom = _reactDom2['default'].findDOMNode(header);
        if (!thDom.style.width) {
          thDom.style.width = thDom.offsetWidth + 'px';
        }
      });
    }
  }, {
    key: 'render',
    value: function render() {
      var _this = this;

      var _props = this.props;
      var columns = _props.columns;
      var keys = _props.keys;
      var buildRowOptions = _props.buildRowOptions;
      var sortBy = _props.sortBy;
      var onSort = _props.onSort;

      var headers = columns.map(function (col, idx) {
        var sortProps = undefined,
            order = undefined;
        // Only add sorting events if the column has a property and is sortable.
        if (typeof onSort == 'function' && col.sortable !== false && 'prop' in col) {
          sortProps = buildSortProps(col, sortBy, onSort);
          order = sortProps['aria-sort'];
        }

        return _react2['default'].createElement(
          'th',
          _extends({
            ref: function (c) {
              return _this._headers[idx] = c;
            },
            key: idx,
            style: { width: col.width },
            role: 'columnheader',
            scope: 'col'
          }, sortProps),
          _react2['default'].createElement(
            'span',
            null,
            col.title
          ),
          typeof order != 'undefined' ? _react2['default'].createElement('span', { className: 'sort-icon sort-' + order, 'aria-hidden': 'true' }) : null
        );
      });

      var getKeys = Array.isArray(keys) ? keyGetter(keys) : simpleGet(keys);
      var rows = this.props.dataArray.map(function (row) {
        return _react2['default'].createElement(
          'tr',
          _extends({ key: getKeys(row) }, buildRowOptions(row)),
          columns.map(function (col, i) {
            return _react2['default'].createElement(
              'td',
              { key: i, className: getCellClass(col, row) },
              getCellValue(col, row)
            );
          })
        );
      });

      return _react2['default'].createElement(
        'table',
        this.props,
        _react2['default'].createElement(
          'caption',
          { className: 'sr-only', role: 'alert', 'aria-live': 'polite' },
          'Sorted by ' + sortBy.prop + ': ' + sortBy.order + ' order'
        ),
        _react2['default'].createElement(
          'thead',
          null,
          _react2['default'].createElement(
            'tr',
            null,
            headers
          )
        ),
        _react2['default'].createElement(
          'tbody',
          null,
          rows.length ? rows : _react2['default'].createElement(
            'tr',
            null,
            _react2['default'].createElement(
              'td',
              { colSpan: columns.length, className: 'text-center' },
              'No data'
            )
          )
        )
      );
    }
  }], [{
    key: 'defaultProps',
    value: {
      buildRowOptions: function buildRowOptions() {
        return {};
      },
      sortBy: {}
    },
    enumerable: true
  }, {
    key: 'propTypes',
    value: {
      keys: _react.PropTypes.oneOfType([_react.PropTypes.arrayOf(_react.PropTypes.string), _react.PropTypes.string]).isRequired,

      columns: _react.PropTypes.arrayOf(_react.PropTypes.shape({
        title: _react.PropTypes.string.isRequired,
        prop: _react.PropTypes.oneOfType([_react.PropTypes.string, _react.PropTypes.number]),
        render: _react.PropTypes.func,
        sortable: _react.PropTypes.bool,
        defaultContent: _react.PropTypes.string,
        width: _react.PropTypes.oneOfType([_react.PropTypes.string, _react.PropTypes.number]),
        className: _react.PropTypes.oneOfType([_react.PropTypes.string, _react.PropTypes.func])
      })).isRequired,

      dataArray: _react.PropTypes.arrayOf(_react.PropTypes.oneOfType([_react.PropTypes.array, _react.PropTypes.object])).isRequired,

      buildRowOptions: _react.PropTypes.func,

      sortBy: _react.PropTypes.shape({
        prop: _react.PropTypes.oneOfType([_react.PropTypes.string, _react.PropTypes.number]),
        order: _react.PropTypes.oneOf(['ascending', 'descending'])
      }),

      onSort: _react.PropTypes.func
    },
    enumerable: true
  }]);

  return Table;
})(_react.Component);

exports['default'] = Table;
module.exports = exports['default'];