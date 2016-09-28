'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _compareObjects = require('./compareObjects');

var _compareObjects2 = _interopRequireDefault(_compareObjects);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Item = function (_Component) {
  _inherits(Item, _Component);

  function Item() {
    _classCallCheck(this, Item);

    var _this = _possibleConstructorReturn(this, (Item.__proto__ || Object.getPrototypeOf(Item)).call(this));

    _this.storeItemReference = _this.storeItemReference.bind(_this);
    _this.onMouseEnter = _this.onMouseEnter.bind(_this);
    _this.onMouseLeave = _this.onMouseLeave.bind(_this);
    _this.onMouseDown = _this.onMouseDown.bind(_this);
    _this.onClick = _this.onClick.bind(_this);
    return _this;
  }

  _createClass(Item, [{
    key: 'shouldComponentUpdate',
    value: function shouldComponentUpdate(nextProps) {
      return (0, _compareObjects2.default)(nextProps, this.props, ['renderItemData']);
    }
  }, {
    key: 'storeItemReference',
    value: function storeItemReference(item) {
      if (item !== null) {
        this.item = item;
      }
    }
  }, {
    key: 'onMouseEnter',
    value: function onMouseEnter(event) {
      var _props = this.props;
      var sectionIndex = _props.sectionIndex;
      var itemIndex = _props.itemIndex;


      this.props.onMouseEnter(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
    }
  }, {
    key: 'onMouseLeave',
    value: function onMouseLeave(event) {
      var _props2 = this.props;
      var sectionIndex = _props2.sectionIndex;
      var itemIndex = _props2.itemIndex;


      this.props.onMouseLeave(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
    }
  }, {
    key: 'onMouseDown',
    value: function onMouseDown(event) {
      var _props3 = this.props;
      var sectionIndex = _props3.sectionIndex;
      var itemIndex = _props3.itemIndex;


      this.props.onMouseDown(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
    }
  }, {
    key: 'onClick',
    value: function onClick(event) {
      var _props4 = this.props;
      var sectionIndex = _props4.sectionIndex;
      var itemIndex = _props4.itemIndex;


      this.props.onClick(event, { sectionIndex: sectionIndex, itemIndex: itemIndex });
    }
  }, {
    key: 'render',
    value: function render() {
      var _props5 = this.props;
      var item = _props5.item;
      var renderItem = _props5.renderItem;
      var renderItemData = _props5.renderItemData;

      var restProps = _objectWithoutProperties(_props5, ['item', 'renderItem', 'renderItemData']);

      delete restProps.sectionIndex;
      delete restProps.itemIndex;

      if (typeof restProps.onMouseEnter === 'function') {
        restProps.onMouseEnter = this.onMouseEnter;
      }

      if (typeof restProps.onMouseLeave === 'function') {
        restProps.onMouseLeave = this.onMouseLeave;
      }

      if (typeof restProps.onMouseDown === 'function') {
        restProps.onMouseDown = this.onMouseDown;
      }

      if (typeof restProps.onClick === 'function') {
        restProps.onClick = this.onClick;
      }

      return _react2.default.createElement(
        'li',
        _extends({ role: 'option' }, restProps, { ref: this.storeItemReference }),
        renderItem(item, renderItemData)
      );
    }
  }]);

  return Item;
}(_react.Component);

Item.propTypes = {
  sectionIndex: _react.PropTypes.number,
  itemIndex: _react.PropTypes.number.isRequired,
  item: _react.PropTypes.any.isRequired,
  renderItem: _react.PropTypes.func.isRequired,
  renderItemData: _react.PropTypes.object.isRequired,
  onMouseEnter: _react.PropTypes.func,
  onMouseLeave: _react.PropTypes.func,
  onMouseDown: _react.PropTypes.func,
  onClick: _react.PropTypes.func
};
exports.default = Item;