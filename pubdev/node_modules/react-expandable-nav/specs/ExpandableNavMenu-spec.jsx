'use strict';

var React = require('react/addons'),
    ReactTestUtils = React.addons.TestUtils;

var chai = require('chai');
var expect = chai.expect;

var ExpandableNavMenu = require('../build/components/ExpandableNavMenu'),
    ExpandableNavMenuItem = require('../build/components/ExpandableNavMenuItem');

var mocks = require('./helpers/mocks');

describe('ExpandableNavMenu', function() {
  var instance;

  var smallStyle = {small: 'small'},
      fullStyle = {full: 'full'};

  before(function() {
    var jquery = mocks.jquery;

    instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavMenu>
        <ExpandableNavMenuItem ref="a" jquery={jquery} />
        <ExpandableNavMenuItem ref="b" jquery={jquery} />
      </ExpandableNavMenu>

    );
  });

  it('renders an ul element', function() {
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'ul')).to.exist();
  });

  it('changes active state when children is clicked', function() {
    ReactTestUtils.Simulate.click(instance.refs.b.refs.link);
    expect(instance.state.active).to.equal(1);
  });

  it('accepts fullClass prop as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavMenu fullClass={'full'} expanded={true} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'ul').props.className.split(' ')).to.contain('full');
  });

  it('accepts smallClass prop as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavMenu smallClass={'small'} expanded={false} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'ul').props.className.split(' ')).to.contain('small');
  });
});
