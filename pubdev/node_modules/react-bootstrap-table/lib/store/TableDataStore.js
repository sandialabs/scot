/* eslint no-nested-ternary: 0 */
/* eslint guard-for-in: 0 */
/* eslint no-console: 0 */
/* eslint eqeqeq: 0 */
'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

var _Const = require('../Const');

var _Const2 = _interopRequireDefault(_Const);

function _sort(arr, sortField, order, sortFunc, sortFuncExtraData) {
  order = order.toLowerCase();
  var isDesc = order === _Const2['default'].SORT_DESC;
  arr.sort(function (a, b) {
    if (sortFunc) {
      return sortFunc(a, b, order, sortField, sortFuncExtraData);
    } else {
      if (isDesc) {
        if (b[sortField] === null) return false;
        if (a[sortField] === null) return true;
        if (typeof b[sortField] === 'string') {
          return b[sortField].localeCompare(a[sortField]);
        } else {
          return a[sortField] > b[sortField] ? -1 : a[sortField] < b[sortField] ? 1 : 0;
        }
      } else {
        if (b[sortField] === null) return true;
        if (a[sortField] === null) return false;
        if (typeof a[sortField] === 'string') {
          return a[sortField].localeCompare(b[sortField]);
        } else {
          return a[sortField] < b[sortField] ? -1 : a[sortField] > b[sortField] ? 1 : 0;
        }
      }
    }
  });

  return arr;
}

var TableDataStore = (function () {
  function TableDataStore(data) {
    _classCallCheck(this, TableDataStore);

    this.data = data;
    this.colInfos = null;
    this.filteredData = null;
    this.isOnFilter = false;
    this.filterObj = null;
    this.searchText = null;
    this.sortObj = null;
    this.pageObj = {};
    this.selected = [];
    this.multiColumnSearch = false;
    this.showOnlySelected = false;
    this.remote = false; // remote data
  }

  _createClass(TableDataStore, [{
    key: 'setProps',
    value: function setProps(props) {
      this.keyField = props.keyField;
      this.enablePagination = props.isPagination;
      this.colInfos = props.colInfos;
      this.remote = props.remote;
      this.multiColumnSearch = props.multiColumnSearch;
    }
  }, {
    key: 'setData',
    value: function setData(data) {
      this.data = data;
      this._refresh();
    }
  }, {
    key: 'getSortInfo',
    value: function getSortInfo() {
      return this.sortObj;
    }
  }, {
    key: 'setSelectedRowKey',
    value: function setSelectedRowKey(selectedRowKeys) {
      this.selected = selectedRowKeys;
    }
  }, {
    key: 'getSelectedRowKeys',
    value: function getSelectedRowKeys() {
      return this.selected;
    }
  }, {
    key: 'getCurrentDisplayData',
    value: function getCurrentDisplayData() {
      if (this.isOnFilter) return this.filteredData;else return this.data;
    }
  }, {
    key: '_refresh',
    value: function _refresh() {
      if (this.isOnFilter) {
        if (this.filterObj !== null) this.filter(this.filterObj);
        if (this.searchText !== null) this.search(this.searchText);
      }
      if (this.sortObj) {
        this.sort(this.sortObj.order, this.sortObj.sortField);
      }
    }
  }, {
    key: 'ignoreNonSelected',
    value: function ignoreNonSelected() {
      var _this = this;

      this.showOnlySelected = !this.showOnlySelected;
      if (this.showOnlySelected) {
        this.isOnFilter = true;
        this.filteredData = this.data.filter(function (row) {
          var result = _this.selected.find(function (x) {
            return row[_this.keyField] === x;
          });
          return typeof result !== 'undefined' ? true : false;
        });
      } else {
        this.isOnFilter = false;
      }
    }
  }, {
    key: 'sort',
    value: function sort(order, sortField) {
      this.sortObj = { order: order, sortField: sortField };

      var currentDisplayData = this.getCurrentDisplayData();
      if (!this.colInfos[sortField]) return this;

      var _colInfos$sortField = this.colInfos[sortField];
      var sortFunc = _colInfos$sortField.sortFunc;
      var sortFuncExtraData = _colInfos$sortField.sortFuncExtraData;

      currentDisplayData = _sort(currentDisplayData, sortField, order, sortFunc, sortFuncExtraData);

      return this;
    }
  }, {
    key: 'page',
    value: function page(_page, sizePerPage) {
      this.pageObj.end = _page * sizePerPage - 1;
      this.pageObj.start = this.pageObj.end - (sizePerPage - 1);
      return this;
    }
  }, {
    key: 'edit',
    value: function edit(newVal, rowIndex, fieldName) {
      var currentDisplayData = this.getCurrentDisplayData();
      var rowKeyCache = undefined;
      if (!this.enablePagination) {
        currentDisplayData[rowIndex][fieldName] = newVal;
        rowKeyCache = currentDisplayData[rowIndex][this.keyField];
      } else {
        currentDisplayData[this.pageObj.start + rowIndex][fieldName] = newVal;
        rowKeyCache = currentDisplayData[this.pageObj.start + rowIndex][this.keyField];
      }
      if (this.isOnFilter) {
        this.data.forEach(function (row) {
          if (row[this.keyField] === rowKeyCache) {
            row[fieldName] = newVal;
          }
        }, this);
        if (this.filterObj !== null) this.filter(this.filterObj);
        if (this.searchText !== null) this.search(this.searchText);
      }
      return this;
    }
  }, {
    key: 'addAtBegin',
    value: function addAtBegin(newObj) {
      if (!newObj[this.keyField] || newObj[this.keyField].toString() === '') {
        throw this.keyField + ' can\'t be empty value.';
      }
      var currentDisplayData = this.getCurrentDisplayData();
      currentDisplayData.forEach(function (row) {
        if (row[this.keyField].toString() === newObj[this.keyField].toString()) {
          throw this.keyField + ' ' + newObj[this.keyField] + ' already exists';
        }
      }, this);
      currentDisplayData.unshift(newObj);
      if (this.isOnFilter) {
        this.data.unshift(newObj);
      }
      this._refresh();
    }
  }, {
    key: 'add',
    value: function add(newObj) {
      if (!newObj[this.keyField] || newObj[this.keyField].toString() === '') {
        throw this.keyField + ' can\'t be empty value.';
      }
      var currentDisplayData = this.getCurrentDisplayData();
      currentDisplayData.forEach(function (row) {
        if (row[this.keyField].toString() === newObj[this.keyField].toString()) {
          throw this.keyField + ' ' + newObj[this.keyField] + ' already exists';
        }
      }, this);

      currentDisplayData.push(newObj);
      if (this.isOnFilter) {
        this.data.push(newObj);
      }
      this._refresh();
    }
  }, {
    key: 'remove',
    value: function remove(rowKey) {
      var _this2 = this;

      var currentDisplayData = this.getCurrentDisplayData();
      var result = currentDisplayData.filter(function (row) {
        return rowKey.indexOf(row[_this2.keyField]) === -1;
      });

      if (this.isOnFilter) {
        this.data = this.data.filter(function (row) {
          return rowKey.indexOf(row[_this2.keyField]) === -1;
        });
        this.filteredData = result;
      } else {
        this.data = result;
      }
    }
  }, {
    key: 'filter',
    value: function filter(filterObj) {
      var _this3 = this;

      if (Object.keys(filterObj).length === 0) {
        this.filteredData = null;
        this.isOnFilter = false;
        this.filterObj = null;
        if (this.searchText !== null) this.search(this.searchText);
      } else {
        this.filterObj = filterObj;
        this.filteredData = this.data.filter(function (row) {
          var valid = true;
          var filterVal = undefined;
          for (var key in filterObj) {
            var targetVal = row[key];

            switch (filterObj[key].type) {
              case _Const2['default'].FILTER_TYPE.NUMBER:
                {
                  filterVal = filterObj[key].value.number;
                  break;
                }
              case _Const2['default'].FILTER_TYPE.CUSTOM:
                {
                  filterVal = typeof filterObj[key].value === 'object' ? undefined : typeof filterObj[key].value === 'string' ? filterObj[key].value.toLowerCase() : filterObj[key].value;
                  break;
                }
              case _Const2['default'].FILTER_TYPE.DATE:
                {
                  filterVal = filterObj[key].value.date;
                  break;
                }
              case _Const2['default'].FILTER_TYPE.REGEX:
                {
                  filterVal = filterObj[key].value;
                  break;
                }
              default:
                {
                  filterVal = typeof filterObj[key].value === 'string' ? filterObj[key].value.toLowerCase() : filterObj[key].value;
                  if (filterVal === undefined) {
                    // Support old filter
                    filterVal = filterObj[key].toLowerCase();
                  }
                  break;
                }
            }

            if (_this3.colInfos[key]) {
              var _colInfos$key = _this3.colInfos[key];
              var format = _colInfos$key.format;
              var filterFormatted = _colInfos$key.filterFormatted;
              var formatExtraData = _colInfos$key.formatExtraData;

              if (filterFormatted && format) {
                targetVal = format(row[key], row, formatExtraData);
              }
            }

            switch (filterObj[key].type) {
              case _Const2['default'].FILTER_TYPE.NUMBER:
                {
                  valid = _this3.filterNumber(targetVal, filterVal, filterObj[key].value.comparator);
                  break;
                }
              case _Const2['default'].FILTER_TYPE.DATE:
                {
                  valid = _this3.filterDate(targetVal, filterVal, filterObj[key].value.comparator);
                  break;
                }
              case _Const2['default'].FILTER_TYPE.REGEX:
                {
                  valid = _this3.filterRegex(targetVal, filterVal);
                  break;
                }
              case _Const2['default'].FILTER_TYPE.CUSTOM:
                {
                  valid = _this3.filterCustom(targetVal, filterVal, filterObj[key].value);
                  break;
                }
              default:
                {
                  valid = _this3.filterText(targetVal, filterVal);
                  break;
                }
            }
            if (!valid) {
              break;
            }
          }
          return valid;
        });
        this.isOnFilter = true;
      }
    }
  }, {
    key: 'filterNumber',
    value: function filterNumber(targetVal, filterVal, comparator) {
      var valid = true;
      switch (comparator) {
        case '=':
          {
            if (targetVal != filterVal) {
              valid = false;
            }
            break;
          }
        case '>':
          {
            if (targetVal <= filterVal) {
              valid = false;
            }
            break;
          }
        case '>=':
          {
            if (targetVal < filterVal) {
              valid = false;
            }
            break;
          }
        case '<':
          {
            if (targetVal >= filterVal) {
              valid = false;
            }
            break;
          }
        case '<=':
          {
            if (targetVal > filterVal) {
              valid = false;
            }
            break;
          }
        case '!=':
          {
            if (targetVal == filterVal) {
              valid = false;
            }
            break;
          }
        default:
          {
            console.error('Number comparator provided is not supported');
            break;
          }
      }
      return valid;
    }
  }, {
    key: 'filterDate',
    value: function filterDate(targetVal, filterVal, comparator) {
      // if (!targetVal) {
      //   return false;
      // }
      // return (targetVal.getDate() === filterVal.getDate() &&
      //     targetVal.getMonth() === filterVal.getMonth() &&
      //     targetVal.getFullYear() === filterVal.getFullYear());

      var valid = true;
      switch (comparator) {
        case '=':
          {
            if (targetVal != filterVal) {
              valid = false;
            }
            break;
          }
        case '>':
          {
            if (targetVal <= filterVal) {
              valid = false;
            }
            break;
          }
        case '>=':
          {
            // console.log(targetVal);
            // console.log(filterVal);
            // console.log(filterVal.getDate());
            if (targetVal < filterVal) {
              valid = false;
            }
            break;
          }
        case '<':
          {
            if (targetVal >= filterVal) {
              valid = false;
            }
            break;
          }
        case '<=':
          {
            if (targetVal > filterVal) {
              valid = false;
            }
            break;
          }
        case '!=':
          {
            if (targetVal == filterVal) {
              valid = false;
            }
            break;
          }
        default:
          {
            console.error('Date comparator provided is not supported');
            break;
          }
      }
      return valid;
    }
  }, {
    key: 'filterRegex',
    value: function filterRegex(targetVal, filterVal) {
      try {
        return new RegExp(filterVal, 'i').test(targetVal);
      } catch (e) {
        console.error('Invalid regular expression');
        return true;
      }
    }
  }, {
    key: 'filterCustom',
    value: function filterCustom(targetVal, filterVal, callbackInfo) {
      if (callbackInfo !== null && typeof callbackInfo === 'object') {
        return callbackInfo.callback(targetVal, callbackInfo.callbackParameters);
      }

      return this.filterText(targetVal, filterVal);
    }
  }, {
    key: 'filterText',
    value: function filterText(targetVal, filterVal) {
      if (targetVal.toString().toLowerCase().indexOf(filterVal) === -1) {
        return false;
      }
      return true;
    }

    /* General search function
     * It will search for the text if the input includes that text;
     */
  }, {
    key: 'search',
    value: function search(searchText) {
      var _this4 = this;

      if (searchText.trim() === '') {
        this.filteredData = null;
        this.isOnFilter = false;
        this.searchText = null;
        if (this.filterObj !== null) this.filter(this.filterObj);
      } else {
        (function () {
          _this4.searchText = searchText;
          var searchTextArray = [];

          if (_this4.multiColumnSearch) {
            searchTextArray = searchText.split(' ');
          } else {
            searchTextArray.push(searchText);
          }
          // Mark following code for fixing #363
          // To avoid to search on a data which be searched or filtered
          // But this solution have a poor performance, because I do a filter again
          // const source = this.isOnFilter ? this.filteredData : this.data;
          var source = _this4.filterObj !== null ? _this4.filter(_this4.filterObj) : _this4.data;

          _this4.filteredData = source.filter(function (row) {
            var keys = Object.keys(row);
            var valid = false;
            // for loops are ugly, but performance matters here.
            // And you cant break from a forEach.
            // http://jsperf.com/for-vs-foreach/66
            for (var i = 0, keysLength = keys.length; i < keysLength; i++) {
              var key = keys[i];
              if (_this4.colInfos[key] && row[key]) {
                var _colInfos$key2 = _this4.colInfos[key];
                var format = _colInfos$key2.format;
                var filterFormatted = _colInfos$key2.filterFormatted;
                var formatExtraData = _colInfos$key2.formatExtraData;
                var searchable = _colInfos$key2.searchable;

                var targetVal = row[key];
                if (searchable) {
                  if (filterFormatted && format) {
                    targetVal = format(targetVal, row, formatExtraData);
                  }
                  for (var j = 0, textLength = searchTextArray.length; j < textLength; j++) {
                    var filterVal = searchTextArray[j].toLowerCase();
                    if (targetVal.toString().toLowerCase().indexOf(filterVal) !== -1) {
                      valid = true;
                      break;
                    }
                  }
                }
              }
            }
            return valid;
          });
          _this4.isOnFilter = true;
        })();
      }
    }
  }, {
    key: 'getDataIgnoringPagination',
    value: function getDataIgnoringPagination() {
      return this.getCurrentDisplayData();
    }
  }, {
    key: 'get',
    value: function get() {
      var _data = this.getCurrentDisplayData();

      if (_data.length === 0) return _data;

      if (this.remote || !this.enablePagination) {
        return _data;
      } else {
        var result = [];
        for (var i = this.pageObj.start; i <= this.pageObj.end; i++) {
          result.push(_data[i]);
          if (i + 1 === _data.length) break;
        }
        return result;
      }
    }
  }, {
    key: 'getKeyField',
    value: function getKeyField() {
      return this.keyField;
    }
  }, {
    key: 'getDataNum',
    value: function getDataNum() {
      return this.getCurrentDisplayData().length;
    }
  }, {
    key: 'isChangedPage',
    value: function isChangedPage() {
      return this.pageObj.start && this.pageObj.end ? true : false;
    }
  }, {
    key: 'isEmpty',
    value: function isEmpty() {
      return this.data.length === 0 || this.data === null || this.data === undefined;
    }
  }, {
    key: 'getAllRowkey',
    value: function getAllRowkey() {
      var _this5 = this;

      return this.data.map(function (row) {
        return row[_this5.keyField];
      });
    }
  }]);

  return TableDataStore;
})();

exports.TableDataStore = TableDataStore;