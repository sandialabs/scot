'use strict';

var React = require('react/addons'),
    ReactTestUtils = React.addons.TestUtils;

var chai = require('chai');
var expect = chai.expect;

var ExpandableNavPage = require('../build/components/ExpandableNavPage');

describe('ExpandableNavPage', function() {
  it('applies fullStyle when expanded is true', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavPage fullStyle={{full: 'full'}} expanded={true} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'div').props.style).to.deep.equal({full: 'full'});
  });

  it('applies smallStyle when expanded is false', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavPage smallStyle={{small: 'small'}} expanded={false} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'div').props.style).to.deep.equal({small: 'small'});
  });

  it('applies fullClass when expanded is true', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavPage fullClass={'full'} expanded={true} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'div').props.className).to.equal('full');
  });

  it('applies smallClass when expanded is false', function() {
    var instance = ReactTestUtils.renderIntoDocument(
      <ExpandableNavPage smallClass={'small'} expanded={false} />
    );
    expect(ReactTestUtils.findRenderedDOMComponentWithTag(instance, 'div').props.className).to.equal('small');
  });
});
