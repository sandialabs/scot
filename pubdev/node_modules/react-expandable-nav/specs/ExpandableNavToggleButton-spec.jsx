'use strict';

var React = require('react/addons'),
    ReactTestUtils = React.addons.TestUtils;

var chai = require('chai');
var expect = chai.expect;

var ExpandableNavToggleButton = require('../build/components/ExpandableNavToggleButton');

describe('ExpandableNavToggleButton', function() {
  it('accepts small prop as an element', function() {
    var small = <button className="small"></button>;
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton small={small} expanded={false}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'button').props.className).to.equal('small');
  });

  it('accepts full prop as an element', function() {
    var full = <button className="full"></button>;
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton full={full} expanded={true}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'button').props.className).to.equal('full');
  });

  it('applies smallStyle when expanded is false', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton smallStyle={{small: 'small'}} expanded={false}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'span').props.style).to.contain({small: 'small'});
  });

  it('applies fullStyle when expanded is true', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton fullStyle={{full: 'full'}} expanded={true}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'span').props.style).to.contain({full: 'full'});
  });

  it('accepts smallClass as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton smallClass="small" expanded={false}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'span').props.className.split(' ')).to.contain('small');
  });

  it('accepts fullClass as a string', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton fullClass="full" expanded={true}/>
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'span').props.className.split(' ')).to.contain('full');
  });

  it('calls handleToggle when button is clicked', function() {
    var spy = sinon.spy();
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavToggleButton handleToggle={spy} />
    );
    ReactTestUtils.Simulate.click(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'span'));
    expect(spy.called).be.true;
  });
});
