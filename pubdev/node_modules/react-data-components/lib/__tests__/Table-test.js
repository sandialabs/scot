'use strict';

jest.dontMock('../Table');

describe('Table', function () {

  var React;
  var TestUtils;
  var Table;

  beforeEach(function () {
    React = require('react');
    TestUtils = require('react-addons-test-utils');
    Table = require('../Table');
  });

  it('shows message when no data', function () {
    var columns = [{ title: 'Test', prop: 'test' }];
    var shallowRenderer = TestUtils.createRenderer();
    shallowRenderer.render(React.createElement(Table, {
      columns: columns,
      dataArray: [],
      keys: 'test'
    }));

    var result = shallowRenderer.getRenderOutput();

    expect(result.props.children[2]).toEqual(React.createElement(
      'tbody',
      null,
      React.createElement(
        'tr',
        null,
        React.createElement(
          'td',
          { colSpan: 1, className: 'text-center' },
          'No data'
        )
      )
    ));
  });

  it('render simple', function () {
    var columns = [{ title: 'Test', prop: 'test' }];
    var shallowRenderer = TestUtils.createRenderer();
    shallowRenderer.render(React.createElement(Table, {
      columns: columns,
      dataArray: [{ test: 'Foo' }],
      keys: 'test'
    }));

    var result = shallowRenderer.getRenderOutput();

    expect(result.props.children[2]).toEqual(React.createElement(
      'tbody',
      null,
      [React.createElement(
        'tr',
        { key: 'Foo', className: undefined },
        [React.createElement(
          'td',
          { key: 0, className: undefined },
          'Foo'
        )]
      )]
    ));
  });
});