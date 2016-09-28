'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _Item = require('./Item');

var _Item2 = _interopRequireDefault(_Item);

var _compareObjects = require('./compareObjects');

var _compareObjects2 = _interopRequireDefault(_compareObjects);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var ItemsList = function (_Component) {
  _inherits(ItemsList, _Component);

  function ItemsList() {
    _classCallCheck(this, ItemsList);

    var _this = _possibleConstructorReturn(this, (ItemsList.__proto__ || Object.getPrototypeOf(ItemsList)).call(this));

    _this.storeFocusedItemReference = _this.storeFocusedItemReference.bind(_this);
    return _this;
  }

  _createClass(ItemsList, [{
    key: 'shouldComponentUpdate',
    value: function shouldComponentUpdate(nextProps) {
      return (0, _compareObjects2.default)(nextProps, this.props, ['itemProps']);
    }
  }, {
    key: 'storeFocusedItemReference',
    value: function storeFocusedItemReference(focusedItem) {
      this.props.onFocusedItemChange(focusedItem === null ? null : focusedItem.item);
    }
  }, {
    key: 'render',
    value: function render() {
      var _this2 = this;

      var _props = this.props;
      var items = _props.items;
      var itemProps = _props.itemProps;
      var renderItem = _props.renderItem;
      var renderItemData = _props.renderItemData;
      var sectionIndex = _props.sectionIndex;
      var focusedItemIndex = _props.focusedItemIndex;
      var getItemId = _props.getItemId;
      var theme = _props.theme;
      var keyPrefix = _props.keyPrefix;

      var sectionPrefix = sectionIndex === null ? keyPrefix : keyPrefix + 'section-' + sectionIndex + '-';
      var isItemPropsFunction = typeof itemProps === 'function';

      return _react2.default.createElement(
        'ul',
        _extends({ role: 'listbox' }, theme(sectionPrefix + 'items-list', 'itemsList')),
        items.map(function (item, itemIndex) {
          var isFocused = itemIndex === focusedItemIndex;
          var itemKey = sectionPrefix + 'item-' + itemIndex;
          var itemPropsObj = isItemPropsFunction ? itemProps({ sectionIndex: sectionIndex, itemIndex: itemIndex }) : itemProps;
          var allItemProps = _extends({
            id: getItemId(sectionIndex, itemIndex)
          }, theme(itemKey, 'item', isFocused && 'itemFocused'), itemPropsObj);

          if (isFocused) {
            allItemProps.ref = _this2.storeFocusedItemReference;
          }

          // `key` is provided by theme()
          /* eslint-disable react/jsx-key */
          return _react2.default.createElement(_Item2.default, _extends({}, allItemProps, {
            sectionIndex: sectionIndex,
            itemIndex: itemIndex,
            item: item,
            renderItem: renderItem,
            renderItemData: renderItemData }));
          /* eslint-enable react/jsx-key */
        })
      );
    }
  }]);

  return ItemsList;
}(_react.Component);

ItemsList.propTypes = {
  items: _react.PropTypes.array.isRequired,
  itemProps: _react.PropTypes.oneOfType([_react.PropTypes.object, _react.PropTypes.func]),
  renderItem: _react.PropTypes.func.isRequired,
  renderItemData: _react.PropTypes.object.isRequired,
  sectionIndex: _react.PropTypes.number,
  focusedItemIndex: _react.PropTypes.number,
  onFocusedItemChange: _react.PropTypes.func.isRequired,
  getItemId: _react.PropTypes.func.isRequired,
  theme: _react.PropTypes.func.isRequired,
  keyPrefix: _react.PropTypes.string.isRequired
};
ItemsList.defaultProps = {
  sectionIndex: null
};
exports.default = ItemsList;