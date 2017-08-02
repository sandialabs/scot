'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _utils = require('./utils');

var _utils2 = _interopRequireDefault(_utils);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

exports.default = function (Base) {
  return function (_Base) {
    _inherits(_class, _Base);

    function _class() {
      _classCallCheck(this, _class);

      return _possibleConstructorReturn(this, (_class.__proto__ || Object.getPrototypeOf(_class)).apply(this, arguments));
    }

    _createClass(_class, [{
      key: 'getResolvedState',
      value: function getResolvedState(props, state) {
        var resolvedState = _extends({}, _utils2.default.compactObject(this.state), _utils2.default.compactObject(this.props), _utils2.default.compactObject(state), _utils2.default.compactObject(props));
        return resolvedState;
      }
    }, {
      key: 'getDataModel',
      value: function getDataModel(newState) {
        var _this2 = this;

        var columns = newState.columns,
            _newState$pivotBy = newState.pivotBy,
            pivotBy = _newState$pivotBy === undefined ? [] : _newState$pivotBy,
            data = newState.data,
            pivotIDKey = newState.pivotIDKey,
            pivotValKey = newState.pivotValKey,
            subRowsKey = newState.subRowsKey,
            aggregatedKey = newState.aggregatedKey,
            nestingLevelKey = newState.nestingLevelKey,
            originalKey = newState.originalKey,
            indexKey = newState.indexKey,
            groupedByPivotKey = newState.groupedByPivotKey,
            SubComponent = newState.SubComponent;

        // Determine Header Groups

        var hasHeaderGroups = false;
        columns.forEach(function (column) {
          if (column.columns) {
            hasHeaderGroups = true;
          }
        });

        var columnsWithExpander = [].concat(_toConsumableArray(columns));

        var expanderColumn = columns.find(function (col) {
          return col.expander || col.columns && col.columns.some(function (col2) {
            return col2.expander;
          });
        });
        // The actual expander might be in the columns field of a group column
        if (expanderColumn && !expanderColumn.expander) {
          expanderColumn = expanderColumn.columns.find(function (col) {
            return col.expander;
          });
        }

        // If we have SubComponent's we need to make sure we have an expander column
        if (SubComponent && !expanderColumn) {
          expanderColumn = { expander: true };
          columnsWithExpander = [expanderColumn].concat(_toConsumableArray(columnsWithExpander));
        }

        var makeDecoratedColumn = function makeDecoratedColumn(column) {
          var dcol = void 0;
          if (column.expander) {
            dcol = _extends({}, _this2.props.column, _this2.props.expanderDefaults, column);
          } else {
            dcol = _extends({}, _this2.props.column, column);
          }

          if (typeof dcol.accessor === 'string') {
            var _ret = function () {
              dcol.id = dcol.id || dcol.accessor;
              var accessorString = dcol.accessor;
              dcol.accessor = function (row) {
                return _utils2.default.get(row, accessorString);
              };
              return {
                v: dcol
              };
            }();

            if ((typeof _ret === 'undefined' ? 'undefined' : _typeof(_ret)) === "object") return _ret.v;
          }

          if (dcol.accessor && !dcol.id) {
            console.warn(dcol);
            throw new Error('A column id is required if using a non-string accessor for column above.');
          }

          if (!dcol.accessor) {
            dcol.accessor = function (d) {
              return undefined;
            };
          }

          // Ensure minWidth is not greater than maxWidth if set
          if (dcol.maxWidth < dcol.minWidth) {
            dcol.minWidth = dcol.maxWidth;
          }

          return dcol;
        };

        // Decorate the columns
        var decorateAndAddToAll = function decorateAndAddToAll(col) {
          var decoratedColumn = makeDecoratedColumn(col);
          allDecoratedColumns.push(decoratedColumn);
          return decoratedColumn;
        };
        var allDecoratedColumns = [];
        var decoratedColumns = columnsWithExpander.map(function (column, i) {
          if (column.columns) {
            return _extends({}, column, {
              columns: column.columns.map(decorateAndAddToAll)
            });
          } else {
            return decorateAndAddToAll(column);
          }
        });

        // Build the visible columns, headers and flat column list
        var visibleColumns = decoratedColumns.slice();
        var allVisibleColumns = [];

        visibleColumns = visibleColumns.map(function (column, i) {
          if (column.columns) {
            var visibleSubColumns = column.columns.filter(function (d) {
              return pivotBy.indexOf(d.id) > -1 ? false : _utils2.default.getFirstDefined(d.show, true);
            });
            return _extends({}, column, {
              columns: visibleSubColumns
            });
          }
          return column;
        });

        visibleColumns = visibleColumns.filter(function (column) {
          return column.columns ? column.columns.length : pivotBy.indexOf(column.id) > -1 ? false : _utils2.default.getFirstDefined(column.show, true);
        });

        // Find any custom pivot location
        var pivotIndex = visibleColumns.findIndex(function (col) {
          return col.pivot;
        });

        // Handle Pivot Columns
        if (pivotBy.length) {
          (function () {
            // Retrieve the pivot columns in the correct pivot order
            var pivotColumns = [];
            pivotBy.forEach(function (pivotID) {
              var found = allDecoratedColumns.find(function (d) {
                return d.id === pivotID;
              });
              if (found) {
                pivotColumns.push(found);
              }
            });

            var pivotColumnGroup = {
              header: function header() {
                return _react2.default.createElement(
                  'strong',
                  null,
                  'Group'
                );
              },
              columns: pivotColumns.map(function (col) {
                return _extends({}, _this2.props.pivotDefaults, col, {
                  pivoted: true
                });
              })
            };

            // Place the pivotColumns back into the visibleColumns
            if (pivotIndex >= 0) {
              pivotColumnGroup = _extends({}, visibleColumns[pivotIndex], pivotColumnGroup);
              visibleColumns.splice(pivotIndex, 1, pivotColumnGroup);
            } else {
              visibleColumns.unshift(pivotColumnGroup);
            }
          })();
        }

        // Build Header Groups
        var headerGroups = [];
        var currentSpan = [];

        // A convenience function to add a header and reset the currentSpan
        var addHeader = function addHeader(columns, column) {
          headerGroups.push(_extends({}, _this2.props.column, column, {
            columns: columns
          }));
          currentSpan = [];
        };

        // Build flast list of allVisibleColumns and HeaderGroups
        visibleColumns.forEach(function (column, i) {
          if (column.columns) {
            allVisibleColumns = allVisibleColumns.concat(column.columns);
            if (currentSpan.length > 0) {
              addHeader(currentSpan);
            }
            addHeader(column.columns, column);
            return;
          }
          allVisibleColumns.push(column);
          currentSpan.push(column);
        });
        if (hasHeaderGroups && currentSpan.length > 0) {
          addHeader(currentSpan);
        }

        // Access the data
        var accessRow = function accessRow(d, i) {
          var _row;

          var level = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;

          var row = (_row = {}, _defineProperty(_row, originalKey, d), _defineProperty(_row, indexKey, i), _defineProperty(_row, subRowsKey, d[subRowsKey]), _defineProperty(_row, nestingLevelKey, level), _row);
          allDecoratedColumns.forEach(function (column) {
            if (column.expander) return;
            row[column.id] = column.accessor(d);
          });
          if (row[subRowsKey]) {
            row[subRowsKey] = row[subRowsKey].map(function (d, i) {
              return accessRow(d, i, level + 1);
            });
          }
          return row;
        };
        var resolvedData = data.map(function (d, i) {
          return accessRow(d, i);
        });

        // If pivoting, recursively group the data
        var aggregate = function aggregate(rows) {
          var aggregationValues = {};
          aggregatingColumns.forEach(function (column) {
            var values = rows.map(function (d) {
              return d[column.id];
            });
            aggregationValues[column.id] = column.aggregate(values, rows);
          });
          return aggregationValues;
        };

        // TODO: Make it possible to fabricate nested rows without pivoting
        var aggregatingColumns = allVisibleColumns.filter(function (d) {
          return !d.expander && d.aggregate;
        });
        if (pivotBy.length) {
          (function () {
            var groupRecursively = function groupRecursively(rows, keys) {
              var i = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;

              // This is the last level, just return the rows
              if (i === keys.length) {
                return rows;
              }
              // Group the rows together for this level
              var groupedRows = Object.entries(_utils2.default.groupBy(rows, keys[i])).map(function (_ref) {
                var _ref3;

                var _ref2 = _slicedToArray(_ref, 2),
                    key = _ref2[0],
                    value = _ref2[1];

                return _ref3 = {}, _defineProperty(_ref3, pivotIDKey, keys[i]), _defineProperty(_ref3, pivotValKey, key), _defineProperty(_ref3, keys[i], key), _defineProperty(_ref3, subRowsKey, value), _defineProperty(_ref3, nestingLevelKey, i), _defineProperty(_ref3, groupedByPivotKey, true), _ref3;
              });
              // Recurse into the subRows
              groupedRows = groupedRows.map(function (rowGroup) {
                var _extends2;

                var subRows = groupRecursively(rowGroup[subRowsKey], keys, i + 1);
                return _extends({}, rowGroup, (_extends2 = {}, _defineProperty(_extends2, subRowsKey, subRows), _defineProperty(_extends2, aggregatedKey, true), _extends2), aggregate(subRows));
              });
              return groupedRows;
            };
            resolvedData = groupRecursively(resolvedData, pivotBy);
          })();
        }

        return _extends({}, newState, {
          resolvedData: resolvedData,
          allVisibleColumns: allVisibleColumns,
          headerGroups: headerGroups,
          allDecoratedColumns: allDecoratedColumns,
          hasHeaderGroups: hasHeaderGroups
        });
      }
    }, {
      key: 'getSortedData',
      value: function getSortedData(resolvedState) {
        var manual = resolvedState.manual,
            sorted = resolvedState.sorted,
            filtered = resolvedState.filtered,
            defaultFilterMethod = resolvedState.defaultFilterMethod,
            resolvedData = resolvedState.resolvedData,
            allVisibleColumns = resolvedState.allVisibleColumns,
            allDecoratedColumns = resolvedState.allDecoratedColumns;


        var sortMethodsByColumnID = {};

        allDecoratedColumns.filter(function (col) {
          return col.sortMethod;
        }).forEach(function (col) {
          sortMethodsByColumnID[col.id] = col.sortMethod;
        });

        // Resolve the data from either manual data or sorted data
        return {
          sortedData: manual ? resolvedData : this.sortData(this.filterData(resolvedData, filtered, defaultFilterMethod, allVisibleColumns), sorted, sortMethodsByColumnID)
        };
      }
    }, {
      key: 'fireFetchData',
      value: function fireFetchData() {
        this.props.onFetchData(this.getResolvedState(), this);
      }
    }, {
      key: 'getPropOrState',
      value: function getPropOrState(key) {
        return _utils2.default.getFirstDefined(this.props[key], this.state[key]);
      }
    }, {
      key: 'getStateOrProp',
      value: function getStateOrProp(key) {
        return _utils2.default.getFirstDefined(this.state[key], this.props[key]);
      }
    }, {
      key: 'filterData',
      value: function filterData(data, filtered, defaultFilterMethod, allVisibleColumns) {
        var _this3 = this;

        var filteredData = data;

        if (filtered.length) {
          filteredData = filtered.reduce(function (filteredSoFar, nextFilter) {
            var column = allVisibleColumns.find(function (x) {
              return x.id === nextFilter.id;
            });

            // Don't filter hidden columns or columns that have had their filters disabled
            if (!column || column.filterable === false) {
              return filteredSoFar;
            }

            var filterMethod = column.filterMethod || defaultFilterMethod;

            // If 'filterAll' is set to true, pass the entire dataset to the filter method
            if (column.filterAll) {
              return filterMethod(nextFilter, filteredSoFar, column);
            } else {
              return filteredSoFar.filter(function (row) {
                return filterMethod(nextFilter, row, column);
              });
            }
          }, filteredData);

          // Apply the filter to the subrows if we are pivoting, and then
          // filter any rows without subcolumns because it would be strange to show
          filteredData = filteredData.map(function (row) {
            if (!row[_this3.props.subRowsKey]) {
              return row;
            }
            return _extends({}, row, _defineProperty({}, _this3.props.subRowsKey, _this3.filterData(row[_this3.props.subRowsKey], filtered, defaultFilterMethod, allVisibleColumns)));
          }).filter(function (row) {
            if (!row[_this3.props.subRowsKey]) {
              return true;
            }
            return row[_this3.props.subRowsKey].length > 0;
          });
        }

        return filteredData;
      }
    }, {
      key: 'sortData',
      value: function sortData(data, sorted) {
        var _this4 = this;

        var sortMethodsByColumnID = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};

        if (!sorted.length) {
          return data;
        }

        var sortedData = (this.props.orderByMethod || _utils2.default.orderBy)(data, sorted.map(function (sort) {
          // Support custom sorting methods for each column
          if (sortMethodsByColumnID[sort.id]) {
            return function (a, b) {
              return sortMethodsByColumnID[sort.id](a[sort.id], b[sort.id]);
            };
          }
          return function (a, b) {
            return _this4.props.defaultSortMethod(a[sort.id], b[sort.id]);
          };
        }), sorted.map(function (d) {
          return !d.desc;
        }), this.props.indexKey);

        sortedData.forEach(function (row) {
          if (!row[_this4.props.subRowsKey]) {
            return;
          }
          row[_this4.props.subRowsKey] = _this4.sortData(row[_this4.props.subRowsKey], sorted, sortMethodsByColumnID);
        });

        return sortedData;
      }
    }, {
      key: 'getMinRows',
      value: function getMinRows() {
        return _utils2.default.getFirstDefined(this.props.minRows, this.getStateOrProp('pageSize'));
      }

      // User actions

    }, {
      key: 'onPageChange',
      value: function onPageChange(page) {
        var _this5 = this;

        var _props = this.props,
            onPageChange = _props.onPageChange,
            collapseOnPageChange = _props.collapseOnPageChange;


        var newState = { page: page };
        if (collapseOnPageChange) {
          newState.expanded = {};
        }
        this.setStateWithData(newState, function () {
          onPageChange && onPageChange(page);
          _this5.fireFetchData();
        });
      }
    }, {
      key: 'onPageSizeChange',
      value: function onPageSizeChange(newPageSize) {
        var _this6 = this;

        var onPageSizeChange = this.props.onPageSizeChange;

        var _getResolvedState = this.getResolvedState(),
            pageSize = _getResolvedState.pageSize,
            page = _getResolvedState.page;

        // Normalize the page to display


        var currentRow = pageSize * page;
        var newPage = Math.floor(currentRow / newPageSize);

        this.setStateWithData({
          pageSize: newPageSize,
          page: newPage
        }, function () {
          onPageSizeChange && onPageSizeChange(newPageSize, newPage);
          _this6.fireFetchData();
        });
      }
    }, {
      key: 'sortColumn',
      value: function sortColumn(column, additive) {
        var _this7 = this;

        var _getResolvedState2 = this.getResolvedState(),
            sorted = _getResolvedState2.sorted,
            skipNextSort = _getResolvedState2.skipNextSort,
            defaultSortDesc = _getResolvedState2.defaultSortDesc;

        var firstSortDirection = column.hasOwnProperty('defaultSortDesc') ? column.defaultSortDesc : defaultSortDesc;
        var secondSortDirection = !firstSortDirection;

        // we can't stop event propagation from the column resize move handlers
        // attached to the document because of react's synthetic events
        // so we have to prevent the sort function from actually sorting
        // if we click on the column resize element within a header.
        if (skipNextSort) {
          this.setStateWithData({
            skipNextSort: false
          });
          return;
        }

        var onSortedChange = this.props.onSortedChange;


        var newSorted = _utils2.default.clone(sorted || []).map(function (d) {
          d.desc = _utils2.default.isSortingDesc(d);
          return d;
        });
        if (!_utils2.default.isArray(column)) {
          // Single-Sort
          var existingIndex = newSorted.findIndex(function (d) {
            return d.id === column.id;
          });
          if (existingIndex > -1) {
            var existing = newSorted[existingIndex];
            if (existing.desc === secondSortDirection) {
              if (additive) {
                newSorted.splice(existingIndex, 1);
              } else {
                existing.desc = firstSortDirection;
                newSorted = [existing];
              }
            } else {
              existing.desc = secondSortDirection;
              if (!additive) {
                newSorted = [existing];
              }
            }
          } else {
            if (additive) {
              newSorted.push({
                id: column.id,
                desc: firstSortDirection
              });
            } else {
              newSorted = [{
                id: column.id,
                desc: firstSortDirection
              }];
            }
          }
        } else {
          (function () {
            // Multi-Sort
            var existingIndex = newSorted.findIndex(function (d) {
              return d.id === column[0].id;
            });
            // Existing Sorted Column
            if (existingIndex > -1) {
              var _existing = newSorted[existingIndex];
              if (_existing.desc === secondSortDirection) {
                if (additive) {
                  newSorted.splice(existingIndex, column.length);
                } else {
                  column.forEach(function (d, i) {
                    newSorted[existingIndex + i].desc = firstSortDirection;
                  });
                }
              } else {
                column.forEach(function (d, i) {
                  newSorted[existingIndex + i].desc = secondSortDirection;
                });
              }
              if (!additive) {
                newSorted = newSorted.slice(existingIndex, column.length);
              }
            } else {
              // New Sort Column
              if (additive) {
                newSorted = newSorted.concat(column.map(function (d) {
                  return {
                    id: d.id,
                    desc: firstSortDirection
                  };
                }));
              } else {
                newSorted = column.map(function (d) {
                  return {
                    id: d.id,
                    desc: firstSortDirection
                  };
                });
              }
            }
          })();
        }

        this.setStateWithData({
          page: !sorted.length && newSorted.length || !additive ? 0 : this.state.page,
          sorted: newSorted
        }, function () {
          onSortedChange && onSortedChange(newSorted, column, additive);
          _this7.fireFetchData();
        });
      }
    }, {
      key: 'filterColumn',
      value: function filterColumn(column, value) {
        var _this8 = this;

        var _getResolvedState3 = this.getResolvedState(),
            filtered = _getResolvedState3.filtered;

        var onFilteredChange = this.props.onFilteredChange;

        // Remove old filter first if it exists

        var newFiltering = (filtered || []).filter(function (x) {
          if (x.id !== column.id) {
            return true;
          }
        });

        if (value !== '') {
          newFiltering.push({
            id: column.id,
            value: value
          });
        }

        this.setStateWithData({
          filtered: newFiltering
        }, function () {
          onFilteredChange && onFilteredChange(newFiltering, column, value);
          _this8.fireFetchData();
        });
      }
    }, {
      key: 'resizeColumnStart',
      value: function resizeColumnStart(column, event, isTouch) {
        var _this9 = this;

        var parentWidth = event.target.parentElement.getBoundingClientRect().width;

        var pageX = void 0;
        if (isTouch) {
          pageX = event.changedTouches[0].pageX;
        } else {
          pageX = event.pageX;
        }

        this.setStateWithData({
          currentlyResizing: {
            id: column.id,
            startX: pageX,
            parentWidth: parentWidth
          }
        }, function () {
          if (isTouch) {
            document.addEventListener('touchmove', _this9.resizeColumnMoving);
            document.addEventListener('touchcancel', _this9.resizeColumnEnd);
            document.addEventListener('touchend', _this9.resizeColumnEnd);
          } else {
            document.addEventListener('mousemove', _this9.resizeColumnMoving);
            document.addEventListener('mouseup', _this9.resizeColumnEnd);
            document.addEventListener('mouseleave', _this9.resizeColumnEnd);
          }
        });
      }
    }, {
      key: 'resizeColumnEnd',
      value: function resizeColumnEnd(event) {
        var isTouch = event.type === 'touchend' || event.type === 'touchcancel';

        if (isTouch) {
          document.removeEventListener('touchmove', this.resizeColumnMoving);
          document.removeEventListener('touchcancel', this.resizeColumnEnd);
          document.removeEventListener('touchend', this.resizeColumnEnd);
        }

        // If its a touch event clear the mouse one's as well because sometimes
        // the mouseDown event gets called as well, but the mouseUp event doesn't
        document.removeEventListener('mousemove', this.resizeColumnMoving);
        document.removeEventListener('mouseup', this.resizeColumnEnd);
        document.removeEventListener('mouseleave', this.resizeColumnEnd);

        // The touch events don't propagate up to the sorting's onMouseDown event so
        // no need to prevent it from happening or else the first click after a touch
        // event resize will not sort the column.
        if (!isTouch) {
          this.setStateWithData({
            skipNextSort: true,
            currentlyResizing: false
          });
        }
      }
    }, {
      key: 'resizeColumnMoving',
      value: function resizeColumnMoving(event) {
        var onResizedChange = this.props.onResizedChange;

        var _getResolvedState4 = this.getResolvedState(),
            resized = _getResolvedState4.resized,
            currentlyResizing = _getResolvedState4.currentlyResizing;

        // Delete old value


        var newResized = resized.filter(function (x) {
          return x.id !== currentlyResizing.id;
        });

        var pageX = void 0;

        if (event.type === 'touchmove') {
          pageX = event.changedTouches[0].pageX;
        } else if (event.type === 'mousemove') {
          pageX = event.pageX;
        }

        // Set the min size to 10 to account for margin and border or else the group headers don't line up correctly
        var newWidth = Math.max(currentlyResizing.parentWidth + pageX - currentlyResizing.startX, 11);

        newResized.push({
          id: currentlyResizing.id,
          value: newWidth
        });

        this.setStateWithData({
          resized: newResized
        }, function () {
          onResizedChange && onResizedChange(newResized, event);
        });
      }
    }]);

    return _class;
  }(Base);
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uL3NyYy9tZXRob2RzLmpzIl0sIm5hbWVzIjpbInByb3BzIiwic3RhdGUiLCJyZXNvbHZlZFN0YXRlIiwiY29tcGFjdE9iamVjdCIsIm5ld1N0YXRlIiwiY29sdW1ucyIsInBpdm90QnkiLCJkYXRhIiwicGl2b3RJREtleSIsInBpdm90VmFsS2V5Iiwic3ViUm93c0tleSIsImFnZ3JlZ2F0ZWRLZXkiLCJuZXN0aW5nTGV2ZWxLZXkiLCJvcmlnaW5hbEtleSIsImluZGV4S2V5IiwiZ3JvdXBlZEJ5UGl2b3RLZXkiLCJTdWJDb21wb25lbnQiLCJoYXNIZWFkZXJHcm91cHMiLCJmb3JFYWNoIiwiY29sdW1uIiwiY29sdW1uc1dpdGhFeHBhbmRlciIsImV4cGFuZGVyQ29sdW1uIiwiZmluZCIsImNvbCIsImV4cGFuZGVyIiwic29tZSIsImNvbDIiLCJtYWtlRGVjb3JhdGVkQ29sdW1uIiwiZGNvbCIsImV4cGFuZGVyRGVmYXVsdHMiLCJhY2Nlc3NvciIsImlkIiwiYWNjZXNzb3JTdHJpbmciLCJnZXQiLCJyb3ciLCJjb25zb2xlIiwid2FybiIsIkVycm9yIiwidW5kZWZpbmVkIiwibWF4V2lkdGgiLCJtaW5XaWR0aCIsImRlY29yYXRlQW5kQWRkVG9BbGwiLCJkZWNvcmF0ZWRDb2x1bW4iLCJhbGxEZWNvcmF0ZWRDb2x1bW5zIiwicHVzaCIsImRlY29yYXRlZENvbHVtbnMiLCJtYXAiLCJpIiwidmlzaWJsZUNvbHVtbnMiLCJzbGljZSIsImFsbFZpc2libGVDb2x1bW5zIiwidmlzaWJsZVN1YkNvbHVtbnMiLCJmaWx0ZXIiLCJpbmRleE9mIiwiZCIsImdldEZpcnN0RGVmaW5lZCIsInNob3ciLCJsZW5ndGgiLCJwaXZvdEluZGV4IiwiZmluZEluZGV4IiwicGl2b3QiLCJwaXZvdENvbHVtbnMiLCJmb3VuZCIsInBpdm90SUQiLCJwaXZvdENvbHVtbkdyb3VwIiwiaGVhZGVyIiwicGl2b3REZWZhdWx0cyIsInBpdm90ZWQiLCJzcGxpY2UiLCJ1bnNoaWZ0IiwiaGVhZGVyR3JvdXBzIiwiY3VycmVudFNwYW4iLCJhZGRIZWFkZXIiLCJjb25jYXQiLCJhY2Nlc3NSb3ciLCJsZXZlbCIsInJlc29sdmVkRGF0YSIsImFnZ3JlZ2F0ZSIsImFnZ3JlZ2F0aW9uVmFsdWVzIiwiYWdncmVnYXRpbmdDb2x1bW5zIiwidmFsdWVzIiwicm93cyIsImdyb3VwUmVjdXJzaXZlbHkiLCJrZXlzIiwiZ3JvdXBlZFJvd3MiLCJPYmplY3QiLCJlbnRyaWVzIiwiZ3JvdXBCeSIsImtleSIsInZhbHVlIiwic3ViUm93cyIsInJvd0dyb3VwIiwibWFudWFsIiwic29ydGVkIiwiZmlsdGVyZWQiLCJkZWZhdWx0RmlsdGVyTWV0aG9kIiwic29ydE1ldGhvZHNCeUNvbHVtbklEIiwic29ydE1ldGhvZCIsInNvcnRlZERhdGEiLCJzb3J0RGF0YSIsImZpbHRlckRhdGEiLCJvbkZldGNoRGF0YSIsImdldFJlc29sdmVkU3RhdGUiLCJmaWx0ZXJlZERhdGEiLCJyZWR1Y2UiLCJmaWx0ZXJlZFNvRmFyIiwibmV4dEZpbHRlciIsIngiLCJmaWx0ZXJhYmxlIiwiZmlsdGVyTWV0aG9kIiwiZmlsdGVyQWxsIiwib3JkZXJCeU1ldGhvZCIsIm9yZGVyQnkiLCJzb3J0IiwiYSIsImIiLCJkZWZhdWx0U29ydE1ldGhvZCIsImRlc2MiLCJtaW5Sb3dzIiwiZ2V0U3RhdGVPclByb3AiLCJwYWdlIiwib25QYWdlQ2hhbmdlIiwiY29sbGFwc2VPblBhZ2VDaGFuZ2UiLCJleHBhbmRlZCIsInNldFN0YXRlV2l0aERhdGEiLCJmaXJlRmV0Y2hEYXRhIiwibmV3UGFnZVNpemUiLCJvblBhZ2VTaXplQ2hhbmdlIiwicGFnZVNpemUiLCJjdXJyZW50Um93IiwibmV3UGFnZSIsIk1hdGgiLCJmbG9vciIsImFkZGl0aXZlIiwic2tpcE5leHRTb3J0IiwiZGVmYXVsdFNvcnREZXNjIiwiZmlyc3RTb3J0RGlyZWN0aW9uIiwiaGFzT3duUHJvcGVydHkiLCJzZWNvbmRTb3J0RGlyZWN0aW9uIiwib25Tb3J0ZWRDaGFuZ2UiLCJuZXdTb3J0ZWQiLCJjbG9uZSIsImlzU29ydGluZ0Rlc2MiLCJpc0FycmF5IiwiZXhpc3RpbmdJbmRleCIsImV4aXN0aW5nIiwib25GaWx0ZXJlZENoYW5nZSIsIm5ld0ZpbHRlcmluZyIsImV2ZW50IiwiaXNUb3VjaCIsInBhcmVudFdpZHRoIiwidGFyZ2V0IiwicGFyZW50RWxlbWVudCIsImdldEJvdW5kaW5nQ2xpZW50UmVjdCIsIndpZHRoIiwicGFnZVgiLCJjaGFuZ2VkVG91Y2hlcyIsImN1cnJlbnRseVJlc2l6aW5nIiwic3RhcnRYIiwiZG9jdW1lbnQiLCJhZGRFdmVudExpc3RlbmVyIiwicmVzaXplQ29sdW1uTW92aW5nIiwicmVzaXplQ29sdW1uRW5kIiwidHlwZSIsInJlbW92ZUV2ZW50TGlzdGVuZXIiLCJvblJlc2l6ZWRDaGFuZ2UiLCJyZXNpemVkIiwibmV3UmVzaXplZCIsIm5ld1dpZHRoIiwibWF4IiwiQmFzZSJdLCJtYXBwaW5ncyI6Ijs7Ozs7Ozs7Ozs7Ozs7QUFBQTs7OztBQUNBOzs7Ozs7Ozs7Ozs7Ozs7O2tCQUVlO0FBQUE7QUFBQTs7QUFBQTtBQUFBOztBQUFBO0FBQUE7O0FBQUE7QUFBQTtBQUFBLHVDQUVPQSxLQUZQLEVBRWNDLEtBRmQsRUFFcUI7QUFDOUIsWUFBTUMsNkJBQ0QsZ0JBQUVDLGFBQUYsQ0FBZ0IsS0FBS0YsS0FBckIsQ0FEQyxFQUVELGdCQUFFRSxhQUFGLENBQWdCLEtBQUtILEtBQXJCLENBRkMsRUFHRCxnQkFBRUcsYUFBRixDQUFnQkYsS0FBaEIsQ0FIQyxFQUlELGdCQUFFRSxhQUFGLENBQWdCSCxLQUFoQixDQUpDLENBQU47QUFNQSxlQUFPRSxhQUFQO0FBQ0Q7QUFWVTtBQUFBO0FBQUEsbUNBWUdFLFFBWkgsRUFZYTtBQUFBOztBQUFBLFlBRXBCQyxPQUZvQixHQWNsQkQsUUFka0IsQ0FFcEJDLE9BRm9CO0FBQUEsZ0NBY2xCRCxRQWRrQixDQUdwQkUsT0FIb0I7QUFBQSxZQUdwQkEsT0FIb0IscUNBR1YsRUFIVTtBQUFBLFlBSXBCQyxJQUpv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ZDtBQUFBLFlBRWpCZ0UsT0FGaUIsc0JBRWpCQSxPQUZpQjtBQUFBLFlBRVJULGlCQUZRLHNCQUVSQSxpQkFGUTs7QUFJekI7OztBQUNBLFlBQU1VLGFBQWFELFFBQVFsSCxNQUFSLENBQWU7QUFBQSxpQkFBS3VELEVBQUU1RSxFQUFGLEtBQVM4SCxrQkFBa0I5SCxFQUFoQztBQUFBLFNBQWYsQ0FBbkI7O0FBRUEsWUFBSTRILGNBQUo7O0FBRUEsWUFBSVAsTUFBTWUsSUFBTixLQUFlLFdBQW5CLEVBQWdDO0FBQzlCUixrQkFBUVAsTUFBTVEsY0FBTixDQUFxQixDQUFyQixFQUF3QkQsS0FBaEM7QUFDRCxTQUZELE1BRU8sSUFBSVAsTUFBTWUsSUFBTixLQUFlLFdBQW5CLEVBQWdDO0FBQ3JDUixrQkFBUVAsTUFBTU8sS0FBZDtBQUNEOztBQUVEO0FBQ0EsWUFBTWEsV0FBV3JDLEtBQUtzQyxHQUFMLENBQ2ZaLGtCQUFrQlAsV0FBbEIsR0FBZ0NLLEtBQWhDLEdBQXdDRSxrQkFBa0JDLE1BRDNDLEVBRWYsRUFGZSxDQUFqQjs7QUFLQVMsbUJBQVczSCxJQUFYLENBQWdCO0FBQ2RiLGNBQUk4SCxrQkFBa0I5SCxFQURSO0FBRWQwRCxpQkFBTytFO0FBRk8sU0FBaEI7O0FBS0EsYUFBSzVDLGdCQUFMLENBQ0U7QUFDRTBDLG1CQUFTQztBQURYLFNBREYsRUFJRSxZQUFNO0FBQ0pGLDZCQUFtQkEsZ0JBQWdCRSxVQUFoQixFQUE0Qm5CLEtBQTVCLENBQW5CO0FBQ0QsU0FOSDtBQVFEO0FBeHJCVTs7QUFBQTtBQUFBLElBQ0NzQixJQUREO0FBQUEsQyIsImZpbGUiOiJtZXRob2RzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IFJlYWN0IGZyb20gJ3JlYWN0J1xuaW1wb3J0IF8gZnJvbSAnLi91dGlscydcblxuZXhwb3J0IGRlZmF1bHQgQmFzZSA9PlxuICBjbGFzcyBleHRlbmRzIEJhc2Uge1xuICAgIGdldFJlc29sdmVkU3RhdGUgKHByb3BzLCBzdGF0ZSkge1xuICAgICAgY29uc3QgcmVzb2x2ZWRTdGF0ZSA9IHtcbiAgICAgICAgLi4uXy5jb21wYWN0T2JqZWN0KHRoaXMuc3RhdGUpLFxuICAgICAgICAuLi5fLmNvbXBhY3RPYmplY3QodGhpcy5wcm9wcyksXG4gICAgICAgIC4uLl8uY29tcGFjdE9iamVjdChzdGF0ZSksXG4gICAgICAgIC4uLl8uY29tcGFjdE9iamVjdChwcm9wcyksXG4gICAgICB9XG4gICAgICByZXR1cm4gcmVzb2x2ZWRTdGF0ZVxuICAgIH1cblxuICAgIGdldERhdGFNb2RlbCAobmV3U3RhdGUpIHtcbiAgICAgIGNvbnN0IHtcbiAgICAgICAgY29sdW1ucyxcbiAgICAgICAgcGl2b3RCeSA9IFtdLFxuICAgICAgICBkYXRhLFxuICAgICAgICBwaXZvdElES2V5LFxuICAgICAgICBwaXZvdFZhbEtleSxcbiAgICAgICAgc3ViUm93c0tleSxcbiAgICAgICAgYWdncmVnYXRlZEtleSxcbiAgICAgICAgbmVzdGluZ0xldmVsS2V5LFxuICAgICAgICBvcmlnaW5hbEtleSxcbiAgICAgICAgaW5kZXhLZXksXG4gICAgICAgIGdyb3VwZWRCeVBpdm90S2V5LFxuICAgICAgICBTdWJDb21wb25lbnQsXG4gICAgICB9ID0gbmV3U3RhdGVcblxuICAgICAgLy8gRGV0ZXJtaW5lIEhlYWRlciBHcm91cHNcbiAgICAgIGxldCBoYXNIZWFkZXJHcm91cHMgPSBmYWxzZVxuICAgICAgY29sdW1ucy5mb3JFYWNoKGNvbHVtbiA9PiB7XG4gICAgICAgIGlmIChjb2x1bW4uY29sdW1ucykge1xuICAgICAgICAgIGhhc0hlYWRlckdyb3VwcyA9IHRydWVcbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgbGV0IGNvbHVtbnNXaXRoRXhwYW5kZXIgPSBbLi4uY29sdW1uc11cblxuICAgICAgbGV0IGV4cGFuZGVyQ29sdW1uID0gY29sdW1ucy5maW5kKFxuICAgICAgICBjb2wgPT5cbiAgICAgICAgICBjb2wuZXhwYW5kZXIgfHxcbiAgICAgICAgICAoY29sLmNvbHVtbnMgJiYgY29sLmNvbHVtbnMuc29tZShjb2wyID0+IGNvbDIuZXhwYW5kZXIpKVxuICAgICAgKVxuICAgICAgLy8gVGhlIGFjdHVhbCBleHBhbmRlciBtaWdodCBiZSBpbiB0aGUgY29sdW1ucyBmaWVsZCBvZiBhIGdyb3VwIGNvbHVtblxuICAgICAgaWYgKGV4cGFuZGVyQ29sdW1uICYmICFleHBhbmRlckNvbHVtbi5leHBhbmRlcikge1xuICAgICAgICBleHBhbmRlckNvbHVtbiA9IGV4cGFuZGVyQ29sdW1uLmNvbHVtbnMuZmluZChjb2wgPT4gY29sLmV4cGFuZGVyKVxuICAgICAgfVxuXG4gICAgICAvLyBJZiB3ZSBoYXZlIFN1YkNvbXBvbmVudCdzIHdlIG5lZWQgdG8gbWFrZSBzdXJlIHdlIGhhdmUgYW4gZXhwYW5kZXIgY29sdW1uXG4gICAgICBpZiAoU3ViQ29tcG9uZW50ICYmICFleHBhbmRlckNvbHVtbikge1xuICAgICAgICBleHBhbmRlckNvbHVtbiA9IHsgZXhwYW5kZXI6IHRydWUgfVxuICAgICAgICBjb2x1bW5zV2l0aEV4cGFuZGVyID0gW2V4cGFuZGVyQ29sdW1uLCAuLi5jb2x1bW5zV2l0aEV4cGFuZGVyXVxuICAgICAgfVxuXG4gICAgICBjb25zdCBtYWtlRGVjb3JhdGVkQ29sdW1uID0gY29sdW1uID0+IHtcbiAgICAgICAgbGV0IGRjb2xcbiAgICAgICAgaWYgKGNvbHVtbi5leHBhbmRlcikge1xuICAgICAgICAgIGRjb2wgPSB7XG4gICAgICAgICAgICAuLi50aGlzLnByb3BzLmNvbHVtbixcbiAgICAgICAgICAgIC4uLnRoaXMucHJvcHMuZXhwYW5kZXJEZWZhdWx0cyxcbiAgICAgICAgICAgIC4uLmNvbHVtbixcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZGNvbCA9IHtcbiAgICAgICAgICAgIC4uLnRoaXMucHJvcHMuY29sdW1uLFxuICAgICAgICAgICAgLi4uY29sdW1uLFxuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGlmICh0eXBlb2YgZGNvbC5hY2Nlc3NvciA9PT0gJ3N0cmluZycpIHtcbiAgICAgICAgICBkY29sLmlkID0gZGNvbC5pZCB8fCBkY29sLmFjY2Vzc29yXG4gICAgICAgICAgY29uc3QgYWNjZXNzb3JTdHJpbmcgPSBkY29sLmFjY2Vzc29yXG4gICAgICAgICAgZGNvbC5hY2Nlc3NvciA9IHJvdyA9PiBfLmdldChyb3csIGFjY2Vzc29yU3RyaW5nKVxuICAgICAgICAgIHJldHVybiBkY29sXG4gICAgICAgIH1cblxuICAgICAgICBpZiAoZGNvbC5hY2Nlc3NvciAmJiAhZGNvbC5pZCkge1xuICAgICAgICAgIGNvbnNvbGUud2FybihkY29sKVxuICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcbiAgICAgICAgICAgICdBIGNvbHVtbiBpZCBpcyByZXF1aXJlZCBpZiB1c2luZyBhIG5vbi1zdHJpbmcgYWNjZXNzb3IgZm9yIGNvbHVtbiBhYm92ZS4nXG4gICAgICAgICAgKVxuICAgICAgICB9XG5cbiAgICAgICAgaWYgKCFkY29sLmFjY2Vzc29yKSB7XG4gICAgICAgICAgZGNvbC5hY2Nlc3NvciA9IGQgPT4gdW5kZWZpbmVkXG4gICAgICAgIH1cblxuICAgICAgICAvLyBFbnN1cmUgbWluV2lkdGggaXMgbm90IGdyZWF0ZXIgdGhhbiBtYXhXaWR0aCBpZiBzZXRcbiAgICAgICAgaWYgKGRjb2wubWF4V2lkdGggPCBkY29sLm1pbldpZHRoKSB7XG4gICAgICAgICAgZGNvbC5taW5XaWR0aCA9IGRjb2wubWF4V2lkdGhcbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiBkY29sXG4gICAgICB9XG5cbiAgICAgIC8vIERlY29yYXRlIHRoZSBjb2x1bW5zXG4gICAgICBjb25zdCBkZWNvcmF0ZUFuZEFkZFRvQWxsID0gY29sID0+IHtcbiAgICAgICAgY29uc3QgZGVjb3JhdGVkQ29sdW1uID0gbWFrZURlY29yYXRlZENvbHVtbihjb2wpXG4gICAgICAgIGFsbERlY29yYXRlZENvbHVtbnMucHVzaChkZWNvcmF0ZWRDb2x1bW4pXG4gICAgICAgIHJldHVybiBkZWNvcmF0ZWRDb2x1bW5cbiAgICAgIH1cbiAgICAgIGxldCBhbGxEZWNvcmF0ZWRDb2x1bW5zID0gW11cbiAgICAgIGNvbnN0IGRlY29yYXRlZENvbHVtbnMgPSBjb2x1bW5zV2l0aEV4cGFuZGVyLm1hcCgoY29sdW1uLCBpKSA9PiB7XG4gICAgICAgIGlmIChjb2x1bW4uY29sdW1ucykge1xuICAgICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICAuLi5jb2x1bW4sXG4gICAgICAgICAgICBjb2x1bW5zOiBjb2x1bW4uY29sdW1ucy5tYXAoZGVjb3JhdGVBbmRBZGRUb0FsbCksXG4gICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHJldHVybiBkZWNvcmF0ZUFuZEFkZFRvQWxsKGNvbHVtbilcbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgLy8gQnVpbGQgdGhlIHZpc2libGUgY29sdW1ucywgaGVhZGVycyBhbmQgZmxhdCBjb2x1bW4gbGlzdFxuICAgICAgbGV0IHZpc2libGVDb2x1bW5zID0gZGVjb3JhdGVkQ29sdW1ucy5zbGljZSgpXG4gICAgICBsZXQgYWxsVmlzaWJsZUNvbHVtbnMgPSBbXVxuXG4gICAgICB2aXNpYmxlQ29sdW1ucyA9IHZpc2libGVDb2x1bW5zLm1hcCgoY29sdW1uLCBpKSA9PiB7XG4gICAgICAgIGlmIChjb2x1bW4uY29sdW1ucykge1xuICAgICAgICAgIGNvbnN0IHZpc2libGVTdWJDb2x1bW5zID0gY29sdW1uLmNvbHVtbnMuZmlsdGVyKFxuICAgICAgICAgICAgZCA9PlxuICAgICAgICAgICAgICBwaXZvdEJ5LmluZGV4T2YoZC5pZCkgPiAtMVxuICAgICAgICAgICAgICAgID8gZmFsc2VcbiAgICAgICAgICAgICAgICA6IF8uZ2V0Rmlyc3REZWZpbmVkKGQuc2hvdywgdHJ1ZSlcbiAgICAgICAgICApXG4gICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIC4uLmNvbHVtbixcbiAgICAgICAgICAgIGNvbHVtbnM6IHZpc2libGVTdWJDb2x1bW5zLFxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gY29sdW1uXG4gICAgICB9KVxuXG4gICAgICB2aXNpYmxlQ29sdW1ucyA9IHZpc2libGVDb2x1bW5zLmZpbHRlcihjb2x1bW4gPT4ge1xuICAgICAgICByZXR1cm4gY29sdW1uLmNvbHVtbnNcbiAgICAgICAgICA/IGNvbHVtbi5jb2x1bW5zLmxlbmd0aFxuICAgICAgICAgIDogcGl2b3RCeS5pbmRleE9mKGNvbHVtbi5pZCkgPiAtMVxuICAgICAgICAgICAgPyBmYWxzZVxuICAgICAgICAgICAgOiBfLmdldEZpcnN0RGVmaW5lZChjb2x1bW4uc2hvdywgdHJ1ZSlcbiAgICAgIH0pXG5cbiAgICAgIC8vIEZpbmQgYW55IGN1c3RvbSBwaXZvdCBsb2NhdGlvblxuICAgICAgY29uc3QgcGl2b3RJbmRleCA9IHZpc2libGVDb2x1bW5zLmZpbmRJbmRleChjb2wgPT4gY29sLnBpdm90KVxuXG4gICAgICAvLyBIYW5kbGUgUGl2b3QgQ29sdW1uc1xuICAgICAgaWYgKHBpdm90QnkubGVuZ3RoKSB7XG4gICAgICAgIC8vIFJldHJpZXZlIHRoZSBwaXZvdCBjb2x1bW5zIGluIHRoZSBjb3JyZWN0IHBpdm90IG9yZGVyXG4gICAgICAgIGNvbnN0IHBpdm90Q29sdW1ucyA9IFtdXG4gICAgICAgIHBpdm90QnkuZm9yRWFjaChwaXZvdElEID0+IHtcbiAgICAgICAgICBjb25zdCBmb3VuZCA9IGFsbERlY29yYXRlZENvbHVtbnMuZmluZChkID0+IGQuaWQgPT09IHBpdm90SUQpXG4gICAgICAgICAgaWYgKGZvdW5kKSB7XG4gICAgICAgICAgICBwaXZvdENvbHVtbnMucHVzaChmb3VuZClcbiAgICAgICAgICB9XG4gICAgICAgIH0pXG5cbiAgICAgICAgbGV0IHBpdm90Q29sdW1uR3JvdXAgPSB7XG4gICAgICAgICAgaGVhZGVyOiAoKSA9PiA8c3Ryb25nPkdyb3VwPC9zdHJvbmc+LFxuICAgICAgICAgIGNvbHVtbnM6IHBpdm90Q29sdW1ucy5tYXAoY29sID0+ICh7XG4gICAgICAgICAgICAuLi50aGlzLnByb3BzLnBpdm90RGVmYXVsdHMsXG4gICAgICAgICAgICAuLi5jb2wsXG4gICAgICAgICAgICBwaXZvdGVkOiB0cnVlLFxuICAgICAgICAgIH0pKSxcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIFBsYWNlIHRoZSBwaXZvdENvbHVtbnMgYmFjayBpbnRvIHRoZSB2aXNpYmxlQ29sdW1uc1xuICAgICAgICBpZiAocGl2b3RJbmRleCA+PSAwKSB7XG4gICAgICAgICAgcGl2b3RDb2x1bW5Hcm91cCA9IHtcbiAgICAgICAgICAgIC4uLnZpc2libGVDb2x1bW5zW3Bpdm90SW5kZXhdLFxuICAgICAgICAgICAgLi4ucGl2b3RDb2x1bW5Hcm91cCxcbiAgICAgICAgICB9XG4gICAgICAgICAgdmlzaWJsZUNvbHVtbnMuc3BsaWNlKHBpdm90SW5kZXgsIDEsIHBpdm90Q29sdW1uR3JvdXApXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgdmlzaWJsZUNvbHVtbnMudW5zaGlmdChwaXZvdENvbHVtbkdyb3VwKVxuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIEJ1aWxkIEhlYWRlciBHcm91cHNcbiAgICAgIGNvbnN0IGhlYWRlckdyb3VwcyA9IFtdXG4gICAgICBsZXQgY3VycmVudFNwYW4gPSBbXVxuXG4gICAgICAvLyBBIGNvbnZlbmllbmNlIGZ1bmN0aW9uIHRvIGFkZCBhIGhlYWRlciBhbmQgcmVzZXQgdGhlIGN1cnJlbnRTcGFuXG4gICAgICBjb25zdCBhZGRIZWFkZXIgPSAoY29sdW1ucywgY29sdW1uKSA9PiB7XG4gICAgICAgIGhlYWRlckdyb3Vwcy5wdXNoKHtcbiAgICAgICAgICAuLi50aGlzLnByb3BzLmNvbHVtbixcbiAgICAgICAgICAuLi5jb2x1bW4sXG4gICAgICAgICAgY29sdW1uczogY29sdW1ucyxcbiAgICAgICAgfSlcbiAgICAgICAgY3VycmVudFNwYW4gPSBbXVxuICAgICAgfVxuXG4gICAgICAvLyBCdWlsZCBmbGFzdCBsaXN0IG9mIGFsbFZpc2libGVDb2x1bW5zIGFuZCBIZWFkZXJHcm91cHNcbiAgICAgIHZpc2libGVDb2x1bW5zLmZvckVhY2goKGNvbHVtbiwgaSkgPT4ge1xuICAgICAgICBpZiAoY29sdW1uLmNvbHVtbnMpIHtcbiAgICAgICAgICBhbGxWaXNpYmxlQ29sdW1ucyA9IGFsbFZpc2libGVDb2x1bW5zLmNvbmNhdChjb2x1bW4uY29sdW1ucylcbiAgICAgICAgICBpZiAoY3VycmVudFNwYW4ubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgYWRkSGVhZGVyKGN1cnJlbnRTcGFuKVxuICAgICAgICAgIH1cbiAgICAgICAgICBhZGRIZWFkZXIoY29sdW1uLmNvbHVtbnMsIGNvbHVtbilcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgICBhbGxWaXNpYmxlQ29sdW1ucy5wdXNoKGNvbHVtbilcbiAgICAgICAgY3VycmVudFNwYW4ucHVzaChjb2x1bW4pXG4gICAgICB9KVxuICAgICAgaWYgKGhhc0hlYWRlckdyb3VwcyAmJiBjdXJyZW50U3Bhbi5sZW5ndGggPiAwKSB7XG4gICAgICAgIGFkZEhlYWRlcihjdXJyZW50U3BhbilcbiAgICAgIH1cblxuICAgICAgLy8gQWNjZXNzIHRoZSBkYXRhXG4gICAgICBjb25zdCBhY2Nlc3NSb3cgPSAoZCwgaSwgbGV2ZWwgPSAwKSA9PiB7XG4gICAgICAgIGNvbnN0IHJvdyA9IHtcbiAgICAgICAgICBbb3JpZ2luYWxLZXldOiBkLFxuICAgICAgICAgIFtpbmRleEtleV06IGksXG4gICAgICAgICAgW3N1YlJvd3NLZXldOiBkW3N1YlJvd3NLZXldLFxuICAgICAgICAgIFtuZXN0aW5nTGV2ZWxLZXldOiBsZXZlbCxcbiAgICAgICAgfVxuICAgICAgICBhbGxEZWNvcmF0ZWRDb2x1bW5zLmZvckVhY2goY29sdW1uID0+IHtcbiAgICAgICAgICBpZiAoY29sdW1uLmV4cGFuZGVyKSByZXR1cm5cbiAgICAgICAgICByb3dbY29sdW1uLmlkXSA9IGNvbHVtbi5hY2Nlc3NvcihkKVxuICAgICAgICB9KVxuICAgICAgICBpZiAocm93W3N1YlJvd3NLZXldKSB7XG4gICAgICAgICAgcm93W3N1YlJvd3NLZXldID0gcm93W3N1YlJvd3NLZXldLm1hcCgoZCwgaSkgPT5cbiAgICAgICAgICAgIGFjY2Vzc1JvdyhkLCBpLCBsZXZlbCArIDEpXG4gICAgICAgICAgKVxuICAgICAgICB9XG4gICAgICAgIHJldHVybiByb3dcbiAgICAgIH1cbiAgICAgIGxldCByZXNvbHZlZERhdGEgPSBkYXRhLm1hcCgoZCwgaSkgPT4gYWNjZXNzUm93KGQsIGkpKVxuXG4gICAgICAvLyBJZiBwaXZvdGluZywgcmVjdXJzaXZlbHkgZ3JvdXAgdGhlIGRhdGFcbiAgICAgIGNvbnN0IGFnZ3JlZ2F0ZSA9IHJvd3MgPT4ge1xuICAgICAgICBjb25zdCBhZ2dyZWdhdGlvblZhbHVlcyA9IHt9XG4gICAgICAgIGFnZ3JlZ2F0aW5nQ29sdW1ucy5mb3JFYWNoKGNvbHVtbiA9PiB7XG4gICAgICAgICAgY29uc3QgdmFsdWVzID0gcm93cy5tYXAoZCA9PiBkW2NvbHVtbi5pZF0pXG4gICAgICAgICAgYWdncmVnYXRpb25WYWx1ZXNbY29sdW1uLmlkXSA9IGNvbHVtbi5hZ2dyZWdhdGUodmFsdWVzLCByb3dzKVxuICAgICAgICB9KVxuICAgICAgICByZXR1cm4gYWdncmVnYXRpb25WYWx1ZXNcbiAgICAgIH1cblxuICAgICAgLy8gVE9ETzogTWFrZSBpdCBwb3NzaWJsZSB0byBmYWJyaWNhdGUgbmVzdGVkIHJvd3Mgd2l0aG91dCBwaXZvdGluZ1xuICAgICAgY29uc3QgYWdncmVnYXRpbmdDb2x1bW5zID0gYWxsVmlzaWJsZUNvbHVtbnMuZmlsdGVyKFxuICAgICAgICBkID0+ICFkLmV4cGFuZGVyICYmIGQuYWdncmVnYXRlXG4gICAgICApXG4gICAgICBpZiAocGl2b3RCeS5sZW5ndGgpIHtcbiAgICAgICAgY29uc3QgZ3JvdXBSZWN1cnNpdmVseSA9IChyb3dzLCBrZXlzLCBpID0gMCkgPT4ge1xuICAgICAgICAgIC8vIFRoaXMgaXMgdGhlIGxhc3QgbGV2ZWwsIGp1c3QgcmV0dXJuIHRoZSByb3dzXG4gICAgICAgICAgaWYgKGkgPT09IGtleXMubGVuZ3RoKSB7XG4gICAgICAgICAgICByZXR1cm4gcm93c1xuICAgICAgICAgIH1cbiAgICAgICAgICAvLyBHcm91cCB0aGUgcm93cyB0b2dldGhlciBmb3IgdGhpcyBsZXZlbFxuICAgICAgICAgIGxldCBncm91cGVkUm93cyA9IE9iamVjdC5lbnRyaWVzKFxuICAgICAgICAgICAgXy5ncm91cEJ5KHJvd3MsIGtleXNbaV0pXG4gICAgICAgICAgKS5tYXAoKFtrZXksIHZhbHVlXSkgPT4ge1xuICAgICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgICAgW3Bpdm90SURLZXldOiBrZXlzW2ldLFxuICAgICAgICAgICAgICBbcGl2b3RWYWxLZXldOiBrZXksXG4gICAgICAgICAgICAgIFtrZXlzW2ldXToga2V5LFxuICAgICAgICAgICAgICBbc3ViUm93c0tleV06IHZhbHVlLFxuICAgICAgICAgICAgICBbbmVzdGluZ0xldmVsS2V5XTogaSxcbiAgICAgICAgICAgICAgW2dyb3VwZWRCeVBpdm90S2V5XTogdHJ1ZSxcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KVxuICAgICAgICAgIC8vIFJlY3Vyc2UgaW50byB0aGUgc3ViUm93c1xuICAgICAgICAgIGdyb3VwZWRSb3dzID0gZ3JvdXBlZFJvd3MubWFwKHJvd0dyb3VwID0+IHtcbiAgICAgICAgICAgIGxldCBzdWJSb3dzID0gZ3JvdXBSZWN1cnNpdmVseShyb3dHcm91cFtzdWJSb3dzS2V5XSwga2V5cywgaSArIDEpXG4gICAgICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgICAuLi5yb3dHcm91cCxcbiAgICAgICAgICAgICAgW3N1YlJvd3NLZXldOiBzdWJSb3dzLFxuICAgICAgICAgICAgICBbYWdncmVnYXRlZEtleV06IHRydWUsXG4gICAgICAgICAgICAgIC4uLmFnZ3JlZ2F0ZShzdWJSb3dzKSxcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KVxuICAgICAgICAgIHJldHVybiBncm91cGVkUm93c1xuICAgICAgICB9XG4gICAgICAgIHJlc29sdmVkRGF0YSA9IGdyb3VwUmVjdXJzaXZlbHkocmVzb2x2ZWREYXRhLCBwaXZvdEJ5KVxuICAgICAgfVxuXG4gICAgICByZXR1cm4ge1xuICAgICAgICAuLi5uZXdTdGF0ZSxcbiAgICAgICAgcmVzb2x2ZWREYXRhLFxuICAgICAgICBhbGxWaXNpYmxlQ29sdW1ucyxcbiAgICAgICAgaGVhZGVyR3JvdXBzLFxuICAgICAgICBhbGxEZWNvcmF0ZWRDb2x1bW5zLFxuICAgICAgICBoYXNIZWFkZXJHcm91cHMsXG4gICAgICB9XG4gICAgfVxuXG4gICAgZ2V0U29ydGVkRGF0YSAocmVzb2x2ZWRTdGF0ZSkge1xuICAgICAgY29uc3Qge1xuICAgICAgICBtYW51YWwsXG4gICAgICAgIHNvcnRlZCxcbiAgICAgICAgZmlsdGVyZWQsXG4gICAgICAgIGRlZmF1bHRGaWx0ZXJNZXRob2QsXG4gICAgICAgIHJlc29sdmVkRGF0YSxcbiAgICAgICAgYWxsVmlzaWJsZUNvbHVtbnMsXG4gICAgICAgIGFsbERlY29yYXRlZENvbHVtbnMsXG4gICAgICB9ID0gcmVzb2x2ZWRTdGF0ZVxuXG4gICAgICBjb25zdCBzb3J0TWV0aG9kc0J5Q29sdW1uSUQgPSB7fVxuXG4gICAgICBhbGxEZWNvcmF0ZWRDb2x1bW5zLmZpbHRlcihjb2wgPT4gY29sLnNvcnRNZXRob2QpLmZvckVhY2goY29sID0+IHtcbiAgICAgICAgc29ydE1ldGhvZHNCeUNvbHVtbklEW2NvbC5pZF0gPSBjb2wuc29ydE1ldGhvZFxuICAgICAgfSlcblxuICAgICAgLy8gUmVzb2x2ZSB0aGUgZGF0YSBmcm9tIGVpdGhlciBtYW51YWwgZGF0YSBvciBzb3J0ZWQgZGF0YVxuICAgICAgcmV0dXJuIHtcbiAgICAgICAgc29ydGVkRGF0YTogbWFudWFsXG4gICAgICAgICAgPyByZXNvbHZlZERhdGFcbiAgICAgICAgICA6IHRoaXMuc29ydERhdGEoXG4gICAgICAgICAgICB0aGlzLmZpbHRlckRhdGEoXG4gICAgICAgICAgICAgIHJlc29sdmVkRGF0YSxcbiAgICAgICAgICAgICAgZmlsdGVyZWQsXG4gICAgICAgICAgICAgIGRlZmF1bHRGaWx0ZXJNZXRob2QsXG4gICAgICAgICAgICAgIGFsbFZpc2libGVDb2x1bW5zXG4gICAgICAgICAgICApLFxuICAgICAgICAgICAgc29ydGVkLFxuICAgICAgICAgICAgc29ydE1ldGhvZHNCeUNvbHVtbklEXG4gICAgICAgICAgKSxcbiAgICAgIH1cbiAgICB9XG5cbiAgICBmaXJlRmV0Y2hEYXRhICgpIHtcbiAgICAgIHRoaXMucHJvcHMub25GZXRjaERhdGEodGhpcy5nZXRSZXNvbHZlZFN0YXRlKCksIHRoaXMpXG4gICAgfVxuXG4gICAgZ2V0UHJvcE9yU3RhdGUgKGtleSkge1xuICAgICAgcmV0dXJuIF8uZ2V0Rmlyc3REZWZpbmVkKHRoaXMucHJvcHNba2V5XSwgdGhpcy5zdGF0ZVtrZXldKVxuICAgIH1cblxuICAgIGdldFN0YXRlT3JQcm9wIChrZXkpIHtcbiAgICAgIHJldHVybiBfLmdldEZpcnN0RGVmaW5lZCh0aGlzLnN0YXRlW2tleV0sIHRoaXMucHJvcHNba2V5XSlcbiAgICB9XG5cbiAgICBmaWx0ZXJEYXRhIChkYXRhLCBmaWx0ZXJlZCwgZGVmYXVsdEZpbHRlck1ldGhvZCwgYWxsVmlzaWJsZUNvbHVtbnMpIHtcbiAgICAgIGxldCBmaWx0ZXJlZERhdGEgPSBkYXRhXG5cbiAgICAgIGlmIChmaWx0ZXJlZC5sZW5ndGgpIHtcbiAgICAgICAgZmlsdGVyZWREYXRhID0gZmlsdGVyZWQucmVkdWNlKChmaWx0ZXJlZFNvRmFyLCBuZXh0RmlsdGVyKSA9PiB7XG4gICAgICAgICAgY29uc3QgY29sdW1uID0gYWxsVmlzaWJsZUNvbHVtbnMuZmluZCh4ID0+IHguaWQgPT09IG5leHRGaWx0ZXIuaWQpXG5cbiAgICAgICAgICAvLyBEb24ndCBmaWx0ZXIgaGlkZGVuIGNvbHVtbnMgb3IgY29sdW1ucyB0aGF0IGhhdmUgaGFkIHRoZWlyIGZpbHRlcnMgZGlzYWJsZWRcbiAgICAgICAgICBpZiAoIWNvbHVtbiB8fCBjb2x1bW4uZmlsdGVyYWJsZSA9PT0gZmFsc2UpIHtcbiAgICAgICAgICAgIHJldHVybiBmaWx0ZXJlZFNvRmFyXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgY29uc3QgZmlsdGVyTWV0aG9kID0gY29sdW1uLmZpbHRlck1ldGhvZCB8fCBkZWZhdWx0RmlsdGVyTWV0aG9kXG5cbiAgICAgICAgICAvLyBJZiAnZmlsdGVyQWxsJyBpcyBzZXQgdG8gdHJ1ZSwgcGFzcyB0aGUgZW50aXJlIGRhdGFzZXQgdG8gdGhlIGZpbHRlciBtZXRob2RcbiAgICAgICAgICBpZiAoY29sdW1uLmZpbHRlckFsbCkge1xuICAgICAgICAgICAgcmV0dXJuIGZpbHRlck1ldGhvZChuZXh0RmlsdGVyLCBmaWx0ZXJlZFNvRmFyLCBjb2x1bW4pXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiBmaWx0ZXJlZFNvRmFyLmZpbHRlcihyb3cgPT4ge1xuICAgICAgICAgICAgICByZXR1cm4gZmlsdGVyTWV0aG9kKG5leHRGaWx0ZXIsIHJvdywgY29sdW1uKVxuICAgICAgICAgICAgfSlcbiAgICAgICAgICB9XG4gICAgICAgIH0sIGZpbHRlcmVkRGF0YSlcblxuICAgICAgICAvLyBBcHBseSB0aGUgZmlsdGVyIHRvIHRoZSBzdWJyb3dzIGlmIHdlIGFyZSBwaXZvdGluZywgYW5kIHRoZW5cbiAgICAgICAgLy8gZmlsdGVyIGFueSByb3dzIHdpdGhvdXQgc3ViY29sdW1ucyBiZWNhdXNlIGl0IHdvdWxkIGJlIHN0cmFuZ2UgdG8gc2hvd1xuICAgICAgICBmaWx0ZXJlZERhdGEgPSBmaWx0ZXJlZERhdGFcbiAgICAgICAgICAubWFwKHJvdyA9PiB7XG4gICAgICAgICAgICBpZiAoIXJvd1t0aGlzLnByb3BzLnN1YlJvd3NLZXldKSB7XG4gICAgICAgICAgICAgIHJldHVybiByb3dcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICAgIC4uLnJvdyxcbiAgICAgICAgICAgICAgW3RoaXMucHJvcHMuc3ViUm93c0tleV06IHRoaXMuZmlsdGVyRGF0YShcbiAgICAgICAgICAgICAgICByb3dbdGhpcy5wcm9wcy5zdWJSb3dzS2V5XSxcbiAgICAgICAgICAgICAgICBmaWx0ZXJlZCxcbiAgICAgICAgICAgICAgICBkZWZhdWx0RmlsdGVyTWV0aG9kLFxuICAgICAgICAgICAgICAgIGFsbFZpc2libGVDb2x1bW5zXG4gICAgICAgICAgICAgICksXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSlcbiAgICAgICAgICAuZmlsdGVyKHJvdyA9PiB7XG4gICAgICAgICAgICBpZiAoIXJvd1t0aGlzLnByb3BzLnN1YlJvd3NLZXldKSB7XG4gICAgICAgICAgICAgIHJldHVybiB0cnVlXG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gcm93W3RoaXMucHJvcHMuc3ViUm93c0tleV0ubGVuZ3RoID4gMFxuICAgICAgICAgIH0pXG4gICAgICB9XG5cbiAgICAgIHJldHVybiBmaWx0ZXJlZERhdGFcbiAgICB9XG5cbiAgICBzb3J0RGF0YSAoZGF0YSwgc29ydGVkLCBzb3J0TWV0aG9kc0J5Q29sdW1uSUQgPSB7fSkge1xuICAgICAgaWYgKCFzb3J0ZWQubGVuZ3RoKSB7XG4gICAgICAgIHJldHVybiBkYXRhXG4gICAgICB9XG5cbiAgICAgIGNvbnN0IHNvcnRlZERhdGEgPSAodGhpcy5wcm9wcy5vcmRlckJ5TWV0aG9kIHx8IF8ub3JkZXJCeSkoXG4gICAgICAgIGRhdGEsXG4gICAgICAgIHNvcnRlZC5tYXAoc29ydCA9PiB7XG4gICAgICAgICAgLy8gU3VwcG9ydCBjdXN0b20gc29ydGluZyBtZXRob2RzIGZvciBlYWNoIGNvbHVtblxuICAgICAgICAgIGlmIChzb3J0TWV0aG9kc0J5Q29sdW1uSURbc29ydC5pZF0pIHtcbiAgICAgICAgICAgIHJldHVybiAoYSwgYikgPT4ge1xuICAgICAgICAgICAgICByZXR1cm4gc29ydE1ldGhvZHNCeUNvbHVtbklEW3NvcnQuaWRdKGFbc29ydC5pZF0sIGJbc29ydC5pZF0pXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybiAoYSwgYikgPT4ge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMucHJvcHMuZGVmYXVsdFNvcnRNZXRob2QoYVtzb3J0LmlkXSwgYltzb3J0LmlkXSlcbiAgICAgICAgICB9XG4gICAgICAgIH0pLFxuICAgICAgICBzb3J0ZWQubWFwKGQgPT4gIWQuZGVzYyksXG4gICAgICAgIHRoaXMucHJvcHMuaW5kZXhLZXlcbiAgICAgIClcblxuICAgICAgc29ydGVkRGF0YS5mb3JFYWNoKHJvdyA9PiB7XG4gICAgICAgIGlmICghcm93W3RoaXMucHJvcHMuc3ViUm93c0tleV0pIHtcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgICByb3dbdGhpcy5wcm9wcy5zdWJSb3dzS2V5XSA9IHRoaXMuc29ydERhdGEoXG4gICAgICAgICAgcm93W3RoaXMucHJvcHMuc3ViUm93c0tleV0sXG4gICAgICAgICAgc29ydGVkLFxuICAgICAgICAgIHNvcnRNZXRob2RzQnlDb2x1bW5JRFxuICAgICAgICApXG4gICAgICB9KVxuXG4gICAgICByZXR1cm4gc29ydGVkRGF0YVxuICAgIH1cblxuICAgIGdldE1pblJvd3MgKCkge1xuICAgICAgcmV0dXJuIF8uZ2V0Rmlyc3REZWZpbmVkKFxuICAgICAgICB0aGlzLnByb3BzLm1pblJvd3MsXG4gICAgICAgIHRoaXMuZ2V0U3RhdGVPclByb3AoJ3BhZ2VTaXplJylcbiAgICAgIClcbiAgICB9XG5cbiAgICAvLyBVc2VyIGFjdGlvbnNcbiAgICBvblBhZ2VDaGFuZ2UgKHBhZ2UpIHtcbiAgICAgIGNvbnN0IHsgb25QYWdlQ2hhbmdlLCBjb2xsYXBzZU9uUGFnZUNoYW5nZSB9ID0gdGhpcy5wcm9wc1xuXG4gICAgICBjb25zdCBuZXdTdGF0ZSA9IHsgcGFnZSB9XG4gICAgICBpZiAoY29sbGFwc2VPblBhZ2VDaGFuZ2UpIHtcbiAgICAgICAgbmV3U3RhdGUuZXhwYW5kZWQgPSB7fVxuICAgICAgfVxuICAgICAgdGhpcy5zZXRTdGF0ZVdpdGhEYXRhKG5ld1N0YXRlLCAoKSA9PiB7XG4gICAgICAgIG9uUGFnZUNoYW5nZSAmJiBvblBhZ2VDaGFuZ2UocGFnZSlcbiAgICAgICAgdGhpcy5maXJlRmV0Y2hEYXRhKClcbiAgICAgIH0pXG4gICAgfVxuXG4gICAgb25QYWdlU2l6ZUNoYW5nZSAobmV3UGFnZVNpemUpIHtcbiAgICAgIGNvbnN0IHsgb25QYWdlU2l6ZUNoYW5nZSB9ID0gdGhpcy5wcm9wc1xuICAgICAgY29uc3QgeyBwYWdlU2l6ZSwgcGFnZSB9ID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKClcblxuICAgICAgLy8gTm9ybWFsaXplIHRoZSBwYWdlIHRvIGRpc3BsYXlcbiAgICAgIGNvbnN0IGN1cnJlbnRSb3cgPSBwYWdlU2l6ZSAqIHBhZ2VcbiAgICAgIGNvbnN0IG5ld1BhZ2UgPSBNYXRoLmZsb29yKGN1cnJlbnRSb3cgLyBuZXdQYWdlU2l6ZSlcblxuICAgICAgdGhpcy5zZXRTdGF0ZVdpdGhEYXRhKFxuICAgICAgICB7XG4gICAgICAgICAgcGFnZVNpemU6IG5ld1BhZ2VTaXplLFxuICAgICAgICAgIHBhZ2U6IG5ld1BhZ2UsXG4gICAgICAgIH0sXG4gICAgICAgICgpID0+IHtcbiAgICAgICAgICBvblBhZ2VTaXplQ2hhbmdlICYmIG9uUGFnZVNpemVDaGFuZ2UobmV3UGFnZVNpemUsIG5ld1BhZ2UpXG4gICAgICAgICAgdGhpcy5maXJlRmV0Y2hEYXRhKClcbiAgICAgICAgfVxuICAgICAgKVxuICAgIH1cblxuICAgIHNvcnRDb2x1bW4gKGNvbHVtbiwgYWRkaXRpdmUpIHtcbiAgICAgIGNvbnN0IHsgc29ydGVkLCBza2lwTmV4dFNvcnQsIGRlZmF1bHRTb3J0RGVzYyB9ID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKClcblxuICAgICAgY29uc3QgZmlyc3RTb3J0RGlyZWN0aW9uID0gY29sdW1uLmhhc093blByb3BlcnR5KCdkZWZhdWx0U29ydERlc2MnKVxuICAgICAgICA/IGNvbHVtbi5kZWZhdWx0U29ydERlc2NcbiAgICAgICAgOiBkZWZhdWx0U29ydERlc2NcbiAgICAgIGNvbnN0IHNlY29uZFNvcnREaXJlY3Rpb24gPSAhZmlyc3RTb3J0RGlyZWN0aW9uXG5cbiAgICAgIC8vIHdlIGNhbid0IHN0b3AgZXZlbnQgcHJvcGFnYXRpb24gZnJvbSB0aGUgY29sdW1uIHJlc2l6ZSBtb3ZlIGhhbmRsZXJzXG4gICAgICAvLyBhdHRhY2hlZCB0byB0aGUgZG9jdW1lbnQgYmVjYXVzZSBvZiByZWFjdCdzIHN5bnRoZXRpYyBldmVudHNcbiAgICAgIC8vIHNvIHdlIGhhdmUgdG8gcHJldmVudCB0aGUgc29ydCBmdW5jdGlvbiBmcm9tIGFjdHVhbGx5IHNvcnRpbmdcbiAgICAgIC8vIGlmIHdlIGNsaWNrIG9uIHRoZSBjb2x1bW4gcmVzaXplIGVsZW1lbnQgd2l0aGluIGEgaGVhZGVyLlxuICAgICAgaWYgKHNraXBOZXh0U29ydCkge1xuICAgICAgICB0aGlzLnNldFN0YXRlV2l0aERhdGEoe1xuICAgICAgICAgIHNraXBOZXh0U29ydDogZmFsc2UsXG4gICAgICAgIH0pXG4gICAgICAgIHJldHVyblxuICAgICAgfVxuXG4gICAgICBjb25zdCB7IG9uU29ydGVkQ2hhbmdlIH0gPSB0aGlzLnByb3BzXG5cbiAgICAgIGxldCBuZXdTb3J0ZWQgPSBfLmNsb25lKHNvcnRlZCB8fCBbXSkubWFwKGQgPT4ge1xuICAgICAgICBkLmRlc2MgPSBfLmlzU29ydGluZ0Rlc2MoZClcbiAgICAgICAgcmV0dXJuIGRcbiAgICAgIH0pXG4gICAgICBpZiAoIV8uaXNBcnJheShjb2x1bW4pKSB7XG4gICAgICAgIC8vIFNpbmdsZS1Tb3J0XG4gICAgICAgIGNvbnN0IGV4aXN0aW5nSW5kZXggPSBuZXdTb3J0ZWQuZmluZEluZGV4KGQgPT4gZC5pZCA9PT0gY29sdW1uLmlkKVxuICAgICAgICBpZiAoZXhpc3RpbmdJbmRleCA+IC0xKSB7XG4gICAgICAgICAgY29uc3QgZXhpc3RpbmcgPSBuZXdTb3J0ZWRbZXhpc3RpbmdJbmRleF1cbiAgICAgICAgICBpZiAoZXhpc3RpbmcuZGVzYyA9PT0gc2Vjb25kU29ydERpcmVjdGlvbikge1xuICAgICAgICAgICAgaWYgKGFkZGl0aXZlKSB7XG4gICAgICAgICAgICAgIG5ld1NvcnRlZC5zcGxpY2UoZXhpc3RpbmdJbmRleCwgMSlcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIGV4aXN0aW5nLmRlc2MgPSBmaXJzdFNvcnREaXJlY3Rpb25cbiAgICAgICAgICAgICAgbmV3U29ydGVkID0gW2V4aXN0aW5nXVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBleGlzdGluZy5kZXNjID0gc2Vjb25kU29ydERpcmVjdGlvblxuICAgICAgICAgICAgaWYgKCFhZGRpdGl2ZSkge1xuICAgICAgICAgICAgICBuZXdTb3J0ZWQgPSBbZXhpc3RpbmddXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGlmIChhZGRpdGl2ZSkge1xuICAgICAgICAgICAgbmV3U29ydGVkLnB1c2goe1xuICAgICAgICAgICAgICBpZDogY29sdW1uLmlkLFxuICAgICAgICAgICAgICBkZXNjOiBmaXJzdFNvcnREaXJlY3Rpb24sXG4gICAgICAgICAgICB9KVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBuZXdTb3J0ZWQgPSBbXG4gICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICBpZDogY29sdW1uLmlkLFxuICAgICAgICAgICAgICAgIGRlc2M6IGZpcnN0U29ydERpcmVjdGlvbixcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIF1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIE11bHRpLVNvcnRcbiAgICAgICAgY29uc3QgZXhpc3RpbmdJbmRleCA9IG5ld1NvcnRlZC5maW5kSW5kZXgoZCA9PiBkLmlkID09PSBjb2x1bW5bMF0uaWQpXG4gICAgICAgIC8vIEV4aXN0aW5nIFNvcnRlZCBDb2x1bW5cbiAgICAgICAgaWYgKGV4aXN0aW5nSW5kZXggPiAtMSkge1xuICAgICAgICAgIGNvbnN0IGV4aXN0aW5nID0gbmV3U29ydGVkW2V4aXN0aW5nSW5kZXhdXG4gICAgICAgICAgaWYgKGV4aXN0aW5nLmRlc2MgPT09IHNlY29uZFNvcnREaXJlY3Rpb24pIHtcbiAgICAgICAgICAgIGlmIChhZGRpdGl2ZSkge1xuICAgICAgICAgICAgICBuZXdTb3J0ZWQuc3BsaWNlKGV4aXN0aW5nSW5kZXgsIGNvbHVtbi5sZW5ndGgpXG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICBjb2x1bW4uZm9yRWFjaCgoZCwgaSkgPT4ge1xuICAgICAgICAgICAgICAgIG5ld1NvcnRlZFtleGlzdGluZ0luZGV4ICsgaV0uZGVzYyA9IGZpcnN0U29ydERpcmVjdGlvblxuICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBjb2x1bW4uZm9yRWFjaCgoZCwgaSkgPT4ge1xuICAgICAgICAgICAgICBuZXdTb3J0ZWRbZXhpc3RpbmdJbmRleCArIGldLmRlc2MgPSBzZWNvbmRTb3J0RGlyZWN0aW9uXG4gICAgICAgICAgICB9KVxuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAoIWFkZGl0aXZlKSB7XG4gICAgICAgICAgICBuZXdTb3J0ZWQgPSBuZXdTb3J0ZWQuc2xpY2UoZXhpc3RpbmdJbmRleCwgY29sdW1uLmxlbmd0aClcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gTmV3IFNvcnQgQ29sdW1uXG4gICAgICAgICAgaWYgKGFkZGl0aXZlKSB7XG4gICAgICAgICAgICBuZXdTb3J0ZWQgPSBuZXdTb3J0ZWQuY29uY2F0KFxuICAgICAgICAgICAgICBjb2x1bW4ubWFwKGQgPT4gKHtcbiAgICAgICAgICAgICAgICBpZDogZC5pZCxcbiAgICAgICAgICAgICAgICBkZXNjOiBmaXJzdFNvcnREaXJlY3Rpb24sXG4gICAgICAgICAgICAgIH0pKVxuICAgICAgICAgICAgKVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBuZXdTb3J0ZWQgPSBjb2x1bW4ubWFwKGQgPT4gKHtcbiAgICAgICAgICAgICAgaWQ6IGQuaWQsXG4gICAgICAgICAgICAgIGRlc2M6IGZpcnN0U29ydERpcmVjdGlvbixcbiAgICAgICAgICAgIH0pKVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICB0aGlzLnNldFN0YXRlV2l0aERhdGEoXG4gICAgICAgIHtcbiAgICAgICAgICBwYWdlOlxuICAgICAgICAgICAgKCFzb3J0ZWQubGVuZ3RoICYmIG5ld1NvcnRlZC5sZW5ndGgpIHx8ICFhZGRpdGl2ZVxuICAgICAgICAgICAgICA/IDBcbiAgICAgICAgICAgICAgOiB0aGlzLnN0YXRlLnBhZ2UsXG4gICAgICAgICAgc29ydGVkOiBuZXdTb3J0ZWQsXG4gICAgICAgIH0sXG4gICAgICAgICgpID0+IHtcbiAgICAgICAgICBvblNvcnRlZENoYW5nZSAmJiBvblNvcnRlZENoYW5nZShuZXdTb3J0ZWQsIGNvbHVtbiwgYWRkaXRpdmUpXG4gICAgICAgICAgdGhpcy5maXJlRmV0Y2hEYXRhKClcbiAgICAgICAgfVxuICAgICAgKVxuICAgIH1cblxuICAgIGZpbHRlckNvbHVtbiAoY29sdW1uLCB2YWx1ZSkge1xuICAgICAgY29uc3QgeyBmaWx0ZXJlZCB9ID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKClcbiAgICAgIGNvbnN0IHsgb25GaWx0ZXJlZENoYW5nZSB9ID0gdGhpcy5wcm9wc1xuXG4gICAgICAvLyBSZW1vdmUgb2xkIGZpbHRlciBmaXJzdCBpZiBpdCBleGlzdHNcbiAgICAgIGNvbnN0IG5ld0ZpbHRlcmluZyA9IChmaWx0ZXJlZCB8fCBbXSkuZmlsdGVyKHggPT4ge1xuICAgICAgICBpZiAoeC5pZCAhPT0gY29sdW1uLmlkKSB7XG4gICAgICAgICAgcmV0dXJuIHRydWVcbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgaWYgKHZhbHVlICE9PSAnJykge1xuICAgICAgICBuZXdGaWx0ZXJpbmcucHVzaCh7XG4gICAgICAgICAgaWQ6IGNvbHVtbi5pZCxcbiAgICAgICAgICB2YWx1ZTogdmFsdWUsXG4gICAgICAgIH0pXG4gICAgICB9XG5cbiAgICAgIHRoaXMuc2V0U3RhdGVXaXRoRGF0YShcbiAgICAgICAge1xuICAgICAgICAgIGZpbHRlcmVkOiBuZXdGaWx0ZXJpbmcsXG4gICAgICAgIH0sXG4gICAgICAgICgpID0+IHtcbiAgICAgICAgICBvbkZpbHRlcmVkQ2hhbmdlICYmIG9uRmlsdGVyZWRDaGFuZ2UobmV3RmlsdGVyaW5nLCBjb2x1bW4sIHZhbHVlKVxuICAgICAgICAgIHRoaXMuZmlyZUZldGNoRGF0YSgpXG4gICAgICAgIH1cbiAgICAgIClcbiAgICB9XG5cbiAgICByZXNpemVDb2x1bW5TdGFydCAoY29sdW1uLCBldmVudCwgaXNUb3VjaCkge1xuICAgICAgY29uc3QgcGFyZW50V2lkdGggPSBldmVudC50YXJnZXQucGFyZW50RWxlbWVudC5nZXRCb3VuZGluZ0NsaWVudFJlY3QoKVxuICAgICAgICAud2lkdGhcblxuICAgICAgbGV0IHBhZ2VYXG4gICAgICBpZiAoaXNUb3VjaCkge1xuICAgICAgICBwYWdlWCA9IGV2ZW50LmNoYW5nZWRUb3VjaGVzWzBdLnBhZ2VYXG4gICAgICB9IGVsc2Uge1xuICAgICAgICBwYWdlWCA9IGV2ZW50LnBhZ2VYXG4gICAgICB9XG5cbiAgICAgIHRoaXMuc2V0U3RhdGVXaXRoRGF0YShcbiAgICAgICAge1xuICAgICAgICAgIGN1cnJlbnRseVJlc2l6aW5nOiB7XG4gICAgICAgICAgICBpZDogY29sdW1uLmlkLFxuICAgICAgICAgICAgc3RhcnRYOiBwYWdlWCxcbiAgICAgICAgICAgIHBhcmVudFdpZHRoOiBwYXJlbnRXaWR0aCxcbiAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICAoKSA9PiB7XG4gICAgICAgICAgaWYgKGlzVG91Y2gpIHtcbiAgICAgICAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ3RvdWNobW92ZScsIHRoaXMucmVzaXplQ29sdW1uTW92aW5nKVxuICAgICAgICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcigndG91Y2hjYW5jZWwnLCB0aGlzLnJlc2l6ZUNvbHVtbkVuZClcbiAgICAgICAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ3RvdWNoZW5kJywgdGhpcy5yZXNpemVDb2x1bW5FbmQpXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ21vdXNlbW92ZScsIHRoaXMucmVzaXplQ29sdW1uTW92aW5nKVxuICAgICAgICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignbW91c2V1cCcsIHRoaXMucmVzaXplQ29sdW1uRW5kKVxuICAgICAgICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignbW91c2VsZWF2ZScsIHRoaXMucmVzaXplQ29sdW1uRW5kKVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgKVxuICAgIH1cblxuICAgIHJlc2l6ZUNvbHVtbkVuZCAoZXZlbnQpIHtcbiAgICAgIGxldCBpc1RvdWNoID0gZXZlbnQudHlwZSA9PT0gJ3RvdWNoZW5kJyB8fCBldmVudC50eXBlID09PSAndG91Y2hjYW5jZWwnXG5cbiAgICAgIGlmIChpc1RvdWNoKSB7XG4gICAgICAgIGRvY3VtZW50LnJlbW92ZUV2ZW50TGlzdGVuZXIoJ3RvdWNobW92ZScsIHRoaXMucmVzaXplQ29sdW1uTW92aW5nKVxuICAgICAgICBkb2N1bWVudC5yZW1vdmVFdmVudExpc3RlbmVyKCd0b3VjaGNhbmNlbCcsIHRoaXMucmVzaXplQ29sdW1uRW5kKVxuICAgICAgICBkb2N1bWVudC5yZW1vdmVFdmVudExpc3RlbmVyKCd0b3VjaGVuZCcsIHRoaXMucmVzaXplQ29sdW1uRW5kKVxuICAgICAgfVxuXG4gICAgICAvLyBJZiBpdHMgYSB0b3VjaCBldmVudCBjbGVhciB0aGUgbW91c2Ugb25lJ3MgYXMgd2VsbCBiZWNhdXNlIHNvbWV0aW1lc1xuICAgICAgLy8gdGhlIG1vdXNlRG93biBldmVudCBnZXRzIGNhbGxlZCBhcyB3ZWxsLCBidXQgdGhlIG1vdXNlVXAgZXZlbnQgZG9lc24ndFxuICAgICAgZG9jdW1lbnQucmVtb3ZlRXZlbnRMaXN0ZW5lcignbW91c2Vtb3ZlJywgdGhpcy5yZXNpemVDb2x1bW5Nb3ZpbmcpXG4gICAgICBkb2N1bWVudC5yZW1vdmVFdmVudExpc3RlbmVyKCdtb3VzZXVwJywgdGhpcy5yZXNpemVDb2x1bW5FbmQpXG4gICAgICBkb2N1bWVudC5yZW1vdmVFdmVudExpc3RlbmVyKCdtb3VzZWxlYXZlJywgdGhpcy5yZXNpemVDb2x1bW5FbmQpXG5cbiAgICAgIC8vIFRoZSB0b3VjaCBldmVudHMgZG9uJ3QgcHJvcGFnYXRlIHVwIHRvIHRoZSBzb3J0aW5nJ3Mgb25Nb3VzZURvd24gZXZlbnQgc29cbiAgICAgIC8vIG5vIG5lZWQgdG8gcHJldmVudCBpdCBmcm9tIGhhcHBlbmluZyBvciBlbHNlIHRoZSBmaXJzdCBjbGljayBhZnRlciBhIHRvdWNoXG4gICAgICAvLyBldmVudCByZXNpemUgd2lsbCBub3Qgc29ydCB0aGUgY29sdW1uLlxuICAgICAgaWYgKCFpc1RvdWNoKSB7XG4gICAgICAgIHRoaXMuc2V0U3RhdGVXaXRoRGF0YSh7XG4gICAgICAgICAgc2tpcE5leHRTb3J0OiB0cnVlLFxuICAgICAgICAgIGN1cnJlbnRseVJlc2l6aW5nOiBmYWxzZSxcbiAgICAgICAgfSlcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXNpemVDb2x1bW5Nb3ZpbmcgKGV2ZW50KSB7XG4gICAgICBjb25zdCB7IG9uUmVzaXplZENoYW5nZSB9ID0gdGhpcy5wcm9wc1xuICAgICAgY29uc3QgeyByZXNpemVkLCBjdXJyZW50bHlSZXNpemluZyB9ID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKClcblxuICAgICAgLy8gRGVsZXRlIG9sZCB2YWx1ZVxuICAgICAgY29uc3QgbmV3UmVzaXplZCA9IHJlc2l6ZWQuZmlsdGVyKHggPT4geC5pZCAhPT0gY3VycmVudGx5UmVzaXppbmcuaWQpXG5cbiAgICAgIGxldCBwYWdlWFxuXG4gICAgICBpZiAoZXZlbnQudHlwZSA9PT0gJ3RvdWNobW92ZScpIHtcbiAgICAgICAgcGFnZVggPSBldmVudC5jaGFuZ2VkVG91Y2hlc1swXS5wYWdlWFxuICAgICAgfSBlbHNlIGlmIChldmVudC50eXBlID09PSAnbW91c2Vtb3ZlJykge1xuICAgICAgICBwYWdlWCA9IGV2ZW50LnBhZ2VYXG4gICAgICB9XG5cbiAgICAgIC8vIFNldCB0aGUgbWluIHNpemUgdG8gMTAgdG8gYWNjb3VudCBmb3IgbWFyZ2luIGFuZCBib3JkZXIgb3IgZWxzZSB0aGUgZ3JvdXAgaGVhZGVycyBkb24ndCBsaW5lIHVwIGNvcnJlY3RseVxuICAgICAgY29uc3QgbmV3V2lkdGggPSBNYXRoLm1heChcbiAgICAgICAgY3VycmVudGx5UmVzaXppbmcucGFyZW50V2lkdGggKyBwYWdlWCAtIGN1cnJlbnRseVJlc2l6aW5nLnN0YXJ0WCxcbiAgICAgICAgMTFcbiAgICAgIClcblxuICAgICAgbmV3UmVzaXplZC5wdXNoKHtcbiAgICAgICAgaWQ6IGN1cnJlbnRseVJlc2l6aW5nLmlkLFxuICAgICAgICB2YWx1ZTogbmV3V2lkdGgsXG4gICAgICB9KVxuXG4gICAgICB0aGlzLnNldFN0YXRlV2l0aERhdGEoXG4gICAgICAgIHtcbiAgICAgICAgICByZXNpemVkOiBuZXdSZXNpemVkLFxuICAgICAgICB9LFxuICAgICAgICAoKSA9PiB7XG4gICAgICAgICAgb25SZXNpemVkQ2hhbmdlICYmIG9uUmVzaXplZENoYW5nZShuZXdSZXNpemVkLCBldmVudClcbiAgICAgICAgfVxuICAgICAgKVxuICAgIH1cbiAgfVxuIl19