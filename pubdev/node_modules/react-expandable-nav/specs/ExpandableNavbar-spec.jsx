'use strict';

var React = require('react/addons'),
    ReactTestUtils = React.addons.TestUtils;

var chai = require('chai');
var expect = chai.expect;

var ExpandableNavbar = require('../build/components/ExpandableNavbar');

describe('ExpandableNavbar', function() {
  it('accepts fullWidth prop as a number', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavbar fullWidth={100} expanded={true} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithClass(instance, 'navbar').props.style.width).to.equal(100);
  });

  it('accepts smallWidth prop as a number', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavbar smallWidth={120} expanded={false} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithClass(instance, 'navbar').props.style.width).to.equal(120);
  });

  it('accepts fullClass prop as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavbar fullClass={"full"} expanded={true} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithClass(instance, 'navbar').props.className.split(' ')).to.contain('full');
  });

  it('accepts smallClass prop as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavbar smallClass={"small"} expanded={false} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithClass(instance, 'navbar').props.className.split(' ')).to.contain('small');
  });

  it('applies styles to navbar', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavbar style={{paddingTop: 10}} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithClass(instance, 'navbar').props.style).to.contain({paddingTop: 10});
  })
});
