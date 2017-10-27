'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

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
      key: 'componentWillMount',
      value: function componentWillMount() {
        this.setStateWithData(this.getDataModel(this.getResolvedState()));
      }
    }, {
      key: 'componentDidMount',
      value: function componentDidMount() {
        this.fireFetchData();
      }
    }, {
      key: 'componentWillReceiveProps',
      value: function componentWillReceiveProps(nextProps, nextState) {
        var oldState = this.getResolvedState();
        var newState = this.getResolvedState(nextProps, nextState);

        // Do a deep compare of new and old `defaultOption` and
        // if they are different reset `option = defaultOption`
        var defaultableOptions = ['sorted', 'filtered', 'resized', 'expanded'];
        defaultableOptions.forEach(function (x) {
          var defaultName = 'default' + (x.charAt(0).toUpperCase() + x.slice(1));
          if (JSON.stringify(oldState[defaultName]) !== JSON.stringify(newState[defaultName])) {
            newState[x] = newState[defaultName];
          }
        });

        // If they change these table options, we need to reset defaults
        // or else we could get into a state where the user has changed the UI
        // and then disabled the ability to change it back.
        // e.g. If `filterable` has changed, set `filtered = defaultFiltered`
        var resettableOptions = ['sortable', 'filterable', 'resizable'];
        resettableOptions.forEach(function (x) {
          if (oldState[x] !== newState[x]) {
            var baseName = x.replace('able', '');
            var optionName = baseName + 'ed';
            var defaultName = 'default' + (optionName.charAt(0).toUpperCase() + optionName.slice(1));
            newState[optionName] = newState[defaultName];
          }
        });

        // Props that trigger a data update
        if (oldState.data !== newState.data || oldState.columns !== newState.columns || oldState.pivotBy !== newState.pivotBy || oldState.sorted !== newState.sorted || oldState.filtered !== newState.filtered) {
          this.setStateWithData(this.getDataModel(newState));
        }
      }
    }, {
      key: 'setStateWithData',
      value: function setStateWithData(newState, cb) {
        var _this2 = this;

        var oldState = this.getResolvedState();
        var newResolvedState = this.getResolvedState({}, newState);
        var freezeWhenExpanded = newResolvedState.freezeWhenExpanded;

        // Default to unfrozen state

        newResolvedState.frozen = false;

        // If freezeWhenExpanded is set, check for frozen conditions
        if (freezeWhenExpanded) {
          // if any rows are expanded, freeze the existing data and sorting
          var keys = Object.keys(newResolvedState.expanded);
          for (var i = 0; i < keys.length; i++) {
            if (newResolvedState.expanded[keys[i]]) {
              newResolvedState.frozen = true;
              break;
            }
          }
        }

        // If the data isn't frozen and either the data or
        // sorting model has changed, update the data
        if (oldState.frozen && !newResolvedState.frozen || oldState.sorted !== newResolvedState.sorted || oldState.filtered !== newResolvedState.filtered || oldState.showFilters !== newResolvedState.showFilters || !newResolvedState.frozen && oldState.resolvedData !== newResolvedState.resolvedData) {
          // Handle collapseOnsortedChange & collapseOnDataChange
          if (oldState.sorted !== newResolvedState.sorted && this.props.collapseOnSortingChange || oldState.filtered !== newResolvedState.filtered || oldState.showFilters !== newResolvedState.showFilters || oldState.sortedData && !newResolvedState.frozen && oldState.resolvedData !== newResolvedState.resolvedData && this.props.collapseOnDataChange) {
            newResolvedState.expanded = {};
          }

          Object.assign(newResolvedState, this.getSortedData(newResolvedState));
        }

        // Set page to 0 if filters change
        if (oldState.filtered !== newResolvedState.filtered) {
          newResolvedState.page = 0;
        }

        // Calculate pageSize all the time
        if (newResolvedState.sortedData) {
          newResolvedState.pages = newResolvedState.manual ? newResolvedState.pages : Math.ceil(newResolvedState.sortedData.length / newResolvedState.pageSize);
          newResolvedState.page = Math.max(newResolvedState.page >= newResolvedState.pages ? newResolvedState.pages - 1 : newResolvedState.page, 0);
        }

        return this.setState(newResolvedState, function () {
          cb && cb();
          if (oldState.page !== newResolvedState.page || oldState.pageSize !== newResolvedState.pageSize || oldState.sorted !== newResolvedState.sorted || oldState.filtered !== newResolvedState.filtered) {
            _this2.fireFetchData();
          }
        });
      }
    }]);

    return _class;
  }(Base);
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uL3NyYy9saWZlY3ljbGUuanMiXSwibmFtZXMiOlsic2V0U3RhdGVXaXRoRGF0YSIsImdldERhdGFNb2RlbCIsImdldFJlc29sdmVkU3RhdGUiLCJmaXJlRmV0Y2hEYXRhIiwibmV4dFByb3BzIiwibmV4dFN0YXRlIiwib2xkU3RhdGUiLCJuZXdTdGF0ZSIsImRlZmF1bHRhYmxlT3B0aW9ucyIsImZvckVhY2giLCJkZWZhdWx0TmFtZSIsIngiLCJjaGFyQXQiLCJ0b1VwcGVyQ2FzZSIsInNsaWNlIiwiSlNPTiIsInN0cmluZ2lmeSIsInJlc2V0dGFibGVPcHRpb25zIiwiYmFzZU5hbWUiLCJyZXBsYWNlIiwib3B0aW9uTmFtZSIsImRhdGEiLCJjb2x1bW5zIiwicGl2b3RCeSIsInNvcnRlZCIsImZpbHRlcmVkIiwiY2IiLCJuZXdSZXNvbHZlZFN0YXRlIiwiZnJlZXplV2hlbkV4cGFuZGVkIiwiZnJvemVuIiwia2V5cyIsIk9iamVjdCIsImV4cGFuZGVkIiwiaSIsImxlbmd0aCIsInNob3dGaWx0ZXJzIiwicmVzb2x2ZWREYXRhIiwicHJvcHMiLCJjb2xsYXBzZU9uU29ydGluZ0NoYW5nZSIsInNvcnRlZERhdGEiLCJjb2xsYXBzZU9uRGF0YUNoYW5nZSIsImFzc2lnbiIsImdldFNvcnRlZERhdGEiLCJwYWdlIiwicGFnZXMiLCJtYW51YWwiLCJNYXRoIiwiY2VpbCIsInBhZ2VTaXplIiwibWF4Iiwic2V0U3RhdGUiLCJCYXNlIl0sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7OztrQkFBZTtBQUFBO0FBQUE7O0FBQUE7QUFBQTs7QUFBQTtBQUFBOztBQUFBO0FBQUE7QUFBQSwyQ0FFVztBQUNwQixhQUFLQSxnQkFBTCxDQUFzQixLQUFLQyxZQUFMLENBQWtCLEtBQUtDLGdCQUFMLEVBQWxCLENBQXRCO0FBQ0Q7QUFKVTtBQUFBO0FBQUEsMENBTVU7QUFDbkIsYUFBS0MsYUFBTDtBQUNEO0FBUlU7QUFBQTtBQUFBLGdEQVVnQkMsU0FWaEIsRUFVMkJDLFNB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QUhDLEVBSXRCLENBSnNCLENBQXhCO0FBTUQ7O0FBRUQsZUFBTyxLQUFLTyxRQUFMLENBQWN2QixnQkFBZCxFQUFnQyxZQUFNO0FBQzNDRCxnQkFBTUEsSUFBTjtBQUNBLGNBQ0VwQixTQUFTcUMsSUFBVCxLQUFrQmhCLGlCQUFpQmdCLElBQW5DLElBQ0FyQyxTQUFTMEMsUUFBVCxLQUFzQnJCLGlCQUFpQnFCLFFBRHZDLElBRUExQyxTQUFTa0IsTUFBVCxLQUFvQkcsaUJBQWlCSCxNQUZyQyxJQUdBbEIsU0FBU21CLFFBQVQsS0FBc0JFLGlCQUFpQkYsUUFKekMsRUFLRTtBQUNBLG1CQUFLdEIsYUFBTDtBQUNEO0FBQ0YsU0FWTSxDQUFQO0FBV0Q7QUFwSVU7O0FBQUE7QUFBQSxJQUNDZ0QsSUFERDtBQUFBLEMiLCJmaWxlIjoibGlmZWN5Y2xlLmpzIiwic291cmNlc0NvbnRlbnQiOlsiZXhwb3J0IGRlZmF1bHQgQmFzZSA9PlxuICBjbGFzcyBleHRlbmRzIEJhc2Uge1xuICAgIGNvbXBvbmVudFdpbGxNb3VudCAoKSB7XG4gICAgICB0aGlzLnNldFN0YXRlV2l0aERhdGEodGhpcy5nZXREYXRhTW9kZWwodGhpcy5nZXRSZXNvbHZlZFN0YXRlKCkpKVxuICAgIH1cblxuICAgIGNvbXBvbmVudERpZE1vdW50ICgpIHtcbiAgICAgIHRoaXMuZmlyZUZldGNoRGF0YSgpXG4gICAgfVxuXG4gICAgY29tcG9uZW50V2lsbFJlY2VpdmVQcm9wcyAobmV4dFByb3BzLCBuZXh0U3RhdGUpIHtcbiAgICAgIGNvbnN0IG9sZFN0YXRlID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKClcbiAgICAgIGNvbnN0IG5ld1N0YXRlID0gdGhpcy5nZXRSZXNvbHZlZFN0YXRlKG5leHRQcm9wcywgbmV4dFN0YXRlKVxuXG4gICAgICAvLyBEbyBhIGRlZXAgY29tcGFyZSBvZiBuZXcgYW5kIG9sZCBgZGVmYXVsdE9wdGlvbmAgYW5kXG4gICAgICAvLyBpZiB0aGV5IGFyZSBkaWZmZXJlbnQgcmVzZXQgYG9wdGlvbiA9IGRlZmF1bHRPcHRpb25gXG4gICAgICBjb25zdCBkZWZhdWx0YWJsZU9wdGlvbnMgPSBbJ3NvcnRlZCcsICdmaWx0ZXJlZCcsICdyZXNpemVkJywgJ2V4cGFuZGVkJ11cbiAgICAgIGRlZmF1bHRhYmxlT3B0aW9ucy5mb3JFYWNoKHggPT4ge1xuICAgICAgICBjb25zdCBkZWZhdWx0TmFtZSA9IGBkZWZhdWx0JHt4LmNoYXJBdCgwKS50b1VwcGVyQ2FzZSgpICsgeC5zbGljZSgxKX1gXG4gICAgICAgIGlmIChcbiAgICAgICAgICBKU09OLnN0cmluZ2lmeShvbGRTdGF0ZVtkZWZhdWx0TmFtZV0pICE9PVxuICAgICAgICAgIEpTT04uc3RyaW5naWZ5KG5ld1N0YXRlW2RlZmF1bHROYW1lXSlcbiAgICAgICAgKSB7XG4gICAgICAgICAgbmV3U3RhdGVbeF0gPSBuZXdTdGF0ZVtkZWZhdWx0TmFtZV1cbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgLy8gSWYgdGhleSBjaGFuZ2UgdGhlc2UgdGFibGUgb3B0aW9ucywgd2UgbmVlZCB0byByZXNldCBkZWZhdWx0c1xuICAgICAgLy8gb3IgZWxzZSB3ZSBjb3VsZCBnZXQgaW50byBhIHN0YXRlIHdoZXJlIHRoZSB1c2VyIGhhcyBjaGFuZ2VkIHRoZSBVSVxuICAgICAgLy8gYW5kIHRoZW4gZGlzYWJsZWQgdGhlIGFiaWxpdHkgdG8gY2hhbmdlIGl0IGJhY2suXG4gICAgICAvLyBlLmcuIElmIGBmaWx0ZXJhYmxlYCBoYXMgY2hhbmdlZCwgc2V0IGBmaWx0ZXJlZCA9IGRlZmF1bHRGaWx0ZXJlZGBcbiAgICAgIGNvbnN0IHJlc2V0dGFibGVPcHRpb25zID0gWydzb3J0YWJsZScsICdmaWx0ZXJhYmxlJywgJ3Jlc2l6YWJsZSddXG4gICAgICByZXNldHRhYmxlT3B0aW9ucy5mb3JFYWNoKHggPT4ge1xuICAgICAgICBpZiAob2xkU3RhdGVbeF0gIT09IG5ld1N0YXRlW3hdKSB7XG4gICAgICAgICAgY29uc3QgYmFzZU5hbWUgPSB4LnJlcGxhY2UoJ2FibGUnLCAnJylcbiAgICAgICAgICBjb25zdCBvcHRpb25OYW1lID0gYCR7YmFzZU5hbWV9ZWRgXG4gICAgICAgICAgY29uc3QgZGVmYXVsdE5hbWUgPSBgZGVmYXVsdCR7b3B0aW9uTmFtZS5jaGFyQXQoMCkudG9VcHBlckNhc2UoKSArXG4gICAgICAgICAgICBvcHRpb25OYW1lLnNsaWNlKDEpfWBcbiAgICAgICAgICBuZXdTdGF0ZVtvcHRpb25OYW1lXSA9IG5ld1N0YXRlW2RlZmF1bHROYW1lXVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICAvLyBQcm9wcyB0aGF0IHRyaWdnZXIgYSBkYXRhIHVwZGF0ZVxuICAgICAgaWYgKFxuICAgICAgICBvbGRTdGF0ZS5kYXRhICE9PSBuZXdTdGF0ZS5kYXRhIHx8XG4gICAgICAgIG9sZFN0YXRlLmNvbHVtbnMgIT09IG5ld1N0YXRlLmNvbHVtbnMgfHxcbiAgICAgICAgb2xkU3RhdGUucGl2b3RCeSAhPT0gbmV3U3RhdGUucGl2b3RCeSB8fFxuICAgICAgICBvbGRTdGF0ZS5zb3J0ZWQgIT09IG5ld1N0YXRlLnNvcnRlZCB8fFxuICAgICAgICBvbGRTdGF0ZS5maWx0ZXJlZCAhPT0gbmV3U3RhdGUuZmlsdGVyZWRcbiAgICAgICkge1xuICAgICAgICB0aGlzLnNldFN0YXRlV2l0aERhdGEodGhpcy5nZXREYXRhTW9kZWwobmV3U3RhdGUpKVxuICAgICAgfVxuICAgIH1cblxuICAgIHNldFN0YXRlV2l0aERhdGEgKG5ld1N0YXRlLCBjYikge1xuICAgICAgY29uc3Qgb2xkU3RhdGUgPSB0aGlzLmdldFJlc29sdmVkU3RhdGUoKVxuICAgICAgY29uc3QgbmV3UmVzb2x2ZWRTdGF0ZSA9IHRoaXMuZ2V0UmVzb2x2ZWRTdGF0ZSh7fSwgbmV3U3RhdGUpXG4gICAgICBjb25zdCB7IGZyZWV6ZVdoZW5FeHBhbmRlZCB9ID0gbmV3UmVzb2x2ZWRTdGF0ZVxuXG4gICAgICAvLyBEZWZhdWx0IHRvIHVuZnJvemVuIHN0YXRlXG4gICAgICBuZXdSZXNvbHZlZFN0YXRlLmZyb3plbiA9IGZhbHNlXG5cbiAgICAgIC8vIElmIGZyZWV6ZVdoZW5FeHBhbmRlZCBpcyBzZXQsIGNoZWNrIGZvciBmcm96ZW4gY29uZGl0aW9uc1xuICAgICAgaWYgKGZyZWV6ZVdoZW5FeHBhbmRlZCkge1xuICAgICAgICAvLyBpZiBhbnkgcm93cyBhcmUgZXhwYW5kZWQsIGZyZWV6ZSB0aGUgZXhpc3RpbmcgZGF0YSBhbmQgc29ydGluZ1xuICAgICAgICBjb25zdCBrZXlzID0gT2JqZWN0LmtleXMobmV3UmVzb2x2ZWRTdGF0ZS5leHBhbmRlZClcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBrZXlzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgaWYgKG5ld1Jlc29sdmVkU3RhdGUuZXhwYW5kZWRba2V5c1tpXV0pIHtcbiAgICAgICAgICAgIG5ld1Jlc29sdmVkU3RhdGUuZnJvemVuID0gdHJ1ZVxuICAgICAgICAgICAgYnJlYWtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgLy8gSWYgdGhlIGRhdGEgaXNuJ3QgZnJvemVuIGFuZCBlaXRoZXIgdGhlIGRhdGEgb3JcbiAgICAgIC8vIHNvcnRpbmcgbW9kZWwgaGFzIGNoYW5nZWQsIHVwZGF0ZSB0aGUgZGF0YVxuICAgICAgaWYgKFxuICAgICAgICAob2xkU3RhdGUuZnJvemVuICYmICFuZXdSZXNvbHZlZFN0YXRlLmZyb3plbikgfHxcbiAgICAgICAgb2xkU3RhdGUuc29ydGVkICE9PSBuZXdSZXNvbHZlZFN0YXRlLnNvcnRlZCB8fFxuICAgICAgICBvbGRTdGF0ZS5maWx0ZXJlZCAhPT0gbmV3UmVzb2x2ZWRTdGF0ZS5maWx0ZXJlZCB8fFxuICAgICAgICBvbGRTdGF0ZS5zaG93RmlsdGVycyAhPT0gbmV3UmVzb2x2ZWRTdGF0ZS5zaG93RmlsdGVycyB8fFxuICAgICAgICAoIW5ld1Jlc29sdmVkU3RhdGUuZnJvemVuICYmXG4gICAgICAgICAgb2xkU3RhdGUucmVzb2x2ZWREYXRhICE9PSBuZXdSZXNvbHZlZFN0YXRlLnJlc29sdmVkRGF0YSlcbiAgICAgICkge1xuICAgICAgICAvLyBIYW5kbGUgY29sbGFwc2VPbnNvcnRlZENoYW5nZSAmIGNvbGxhcHNlT25EYXRhQ2hhbmdlXG4gICAgICAgIGlmIChcbiAgICAgICAgICAob2xkU3RhdGUuc29ydGVkICE9PSBuZXdSZXNvbHZlZFN0YXRlLnNvcnRlZCAmJlxuICAgICAgICAgICAgdGhpcy5wcm9wcy5jb2xsYXBzZU9uU29ydGluZ0NoYW5nZSkgfHxcbiAgICAgICAgICBvbGRTdGF0ZS5maWx0ZXJlZCAhPT0gbmV3UmVzb2x2ZWRTdGF0ZS5maWx0ZXJlZCB8fFxuICAgICAgICAgIG9sZFN0YXRlLnNob3dGaWx0ZXJzICE9PSBuZXdSZXNvbHZlZFN0YXRlLnNob3dGaWx0ZXJzIHx8XG4gICAgICAgICAgKG9sZFN0YXRlLnNvcnRlZERhdGEgJiZcbiAgICAgICAgICAgICFuZXdSZXNvbHZlZFN0YXRlLmZyb3plbiAmJlxuICAgICAgICAgICAgb2xkU3RhdGUucmVzb2x2ZWREYXRhICE9PSBuZXdSZXNvbHZlZFN0YXRlLnJlc29sdmVkRGF0YSAmJlxuICAgICAgICAgICAgdGhpcy5wcm9wcy5jb2xsYXBzZU9uRGF0YUNoYW5nZSlcbiAgICAgICAgKSB7XG4gICAgICAgICAgbmV3UmVzb2x2ZWRTdGF0ZS5leHBhbmRlZCA9IHt9XG4gICAgICAgIH1cblxuICAgICAgICBPYmplY3QuYXNzaWduKG5ld1Jlc29sdmVkU3RhdGUsIHRoaXMuZ2V0U29ydGVkRGF0YShuZXdSZXNvbHZlZFN0YXRlKSlcbiAgICAgIH1cblxuICAgICAgLy8gU2V0IHBhZ2UgdG8gMCBpZiBmaWx0ZXJzIGNoYW5nZVxuICAgICAgaWYgKG9sZFN0YXRlLmZpbHRlcmVkICE9PSBuZXdSZXNvbHZlZFN0YXRlLmZpbHRlcmVkKSB7XG4gICAgICAgIG5ld1Jlc29sdmVkU3RhdGUucGFnZSA9IDBcbiAgICAgIH1cblxuICAgICAgLy8gQ2FsY3VsYXRlIHBhZ2VTaXplIGFsbCB0aGUgdGltZVxuICAgICAgaWYgKG5ld1Jlc29sdmVkU3RhdGUuc29ydGVkRGF0YSkge1xuICAgICAgICBuZXdSZXNvbHZlZFN0YXRlLnBhZ2VzID0gbmV3UmVzb2x2ZWRTdGF0ZS5tYW51YWxcbiAgICAgICAgICA/IG5ld1Jlc29sdmVkU3RhdGUucGFnZXNcbiAgICAgICAgICA6IE1hdGguY2VpbChcbiAgICAgICAgICAgIG5ld1Jlc29sdmVkU3RhdGUuc29ydGVkRGF0YS5sZW5ndGggLyBuZXdSZXNvbHZlZFN0YXRlLnBhZ2VTaXplXG4gICAgICAgICAgKVxuICAgICAgICBuZXdSZXNvbHZlZFN0YXRlLnBhZ2UgPSBNYXRoLm1heChcbiAgICAgICAgICBuZXdSZXNvbHZlZFN0YXRlLnBhZ2UgPj0gbmV3UmVzb2x2ZWRTdGF0ZS5wYWdlc1xuICAgICAgICAgICAgPyBuZXdSZXNvbHZlZFN0YXRlLnBhZ2VzIC0gMVxuICAgICAgICAgICAgOiBuZXdSZXNvbHZlZFN0YXRlLnBhZ2UsXG4gICAgICAgICAgMFxuICAgICAgICApXG4gICAgICB9XG5cbiAgICAgIHJldHVybiB0aGlzLnNldFN0YXRlKG5ld1Jlc29sdmVkU3RhdGUsICgpID0+IHtcbiAgICAgICAgY2IgJiYgY2IoKVxuICAgICAgICBpZiAoXG4gICAgICAgICAgb2xkU3RhdGUucGFnZSAhPT0gbmV3UmVzb2x2ZWRTdGF0ZS5wYWdlIHx8XG4gICAgICAgICAgb2xkU3RhdGUucGFnZVNpemUgIT09IG5ld1Jlc29sdmVkU3RhdGUucGFnZVNpemUgfHxcbiAgICAgICAgICBvbGRTdGF0ZS5zb3J0ZWQgIT09IG5ld1Jlc29sdmVkU3RhdGUuc29ydGVkIHx8XG4gICAgICAgICAgb2xkU3RhdGUuZmlsdGVyZWQgIT09IG5ld1Jlc29sdmVkU3RhdGUuZmlsdGVyZWRcbiAgICAgICAgKSB7XG4gICAgICAgICAgdGhpcy5maXJlRmV0Y2hEYXRhKClcbiAgICAgICAgfVxuICAgICAgfSlcbiAgICB9XG4gIH1cbiJdfQ==