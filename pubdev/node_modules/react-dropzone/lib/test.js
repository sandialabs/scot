/* eslint no-unused-expressions: 0 */

'use strict';

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _chai = require('chai');

var _sinon = require('sinon');

var _reactTestutilsAdditions = require('react-testutils-additions');

var _reactTestutilsAdditions2 = _interopRequireDefault(_reactTestutilsAdditions);

var _index = require('./index');

var _index2 = _interopRequireDefault(_index);

describe('Dropzone', function () {

  var files = [];

  beforeEach(function () {
    files = [{
      name: 'file1.pdf',
      size: 1111
    }];
  });

  it('renders the content', function () {
    var dropzone = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(
      _index2['default'],
      null,
      _react2['default'].createElement(
        'div',
        { className: 'dropzone-content' },
        'some content'
      )
    ));
    //
    var content = _reactTestutilsAdditions2['default'].findRenderedDOMComponentWithClass(dropzone, 'dropzone-content');
    _chai.expect(content.textContent).to.equal('some content');
  });

  it('renders the input element', function () {
    var dropzone = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(
      _index2['default'],
      null,
      _react2['default'].createElement(
        'div',
        { className: 'dropzone-content' },
        'some content'
      )
    ));
    var input = _reactTestutilsAdditions2['default'].find(dropzone, 'input');
    _chai.expect(input.length).to.equal(1);
  });

  it('returns the url of the preview', function () {
    var dropSpy = _sinon.spy();
    var dropzone = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(
      _index2['default'],
      { onDrop: dropSpy },
      _react2['default'].createElement(
        'div',
        { className: 'dropzone-content' },
        'some content'
      )
    ));
    var content = _reactTestutilsAdditions2['default'].findRenderedDOMComponentWithClass(dropzone, 'dropzone-content');

    _reactTestutilsAdditions2['default'].Simulate.drop(content, { dataTransfer: { files: files } });
    _chai.expect(dropSpy.callCount).to.equal(1);
    _chai.expect(dropSpy.firstCall.args[0][0]).to.have.property('preview');
  });

  describe('ref', function () {
    it('sets ref properly', function () {
      var dropzone = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], null));
      var input = _reactTestutilsAdditions2['default'].find(dropzone, 'input')[0];

      _chai.expect(dropzone.fileInputEl).to.not.be.undefined;
      _chai.expect(dropzone.fileInputEl).to.eql(input);
    });
  });

  describe('props', function () {

    it('uses the disablePreview property', function () {
      var dropSpy = _sinon.spy();
      var dropzone = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(
        _index2['default'],
        { disablePreview: true, onDrop: dropSpy },
        _react2['default'].createElement(
          'div',
          { className: 'dropzone-content' },
          'some content'
        )
      ));
      var content = _reactTestutilsAdditions2['default'].findRenderedDOMComponentWithClass(dropzone, 'dropzone-content');

      _reactTestutilsAdditions2['default'].Simulate.drop(content, { dataTransfer: { files: files } });
      _chai.expect(dropSpy.callCount).to.equal(1);
      _chai.expect(dropSpy.firstCall.args[0][0]).to.not.have.property('preview');
    });

    it('renders dynamic props on the root element', function () {
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { hidden: true, 'aria-hidden': 'hidden', title: 'Dropzone' }));
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, '[hidden][aria-hidden="hidden"][title="Dropzone"]')).to.have.length(1);
    });

    it('renders dynamic props on the input element', function () {
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { inputProps: { id: 'hiddenFileInput' } }));
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, '#hiddenFileInput')).to.have.length(1);
    });

    it('applies the accept prop to the child input', function () {
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { className: 'my-dropzone', accept: 'image/jpeg' }));
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, 'input[type="file"][accept="image/jpeg"]')).to.have.length(1);
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, '[class="my-dropzone"][accept="image/jpeg"]')).to.have.length(0);
    });

    it('applies the name prop to the child input', function () {
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { className: 'my-dropzone', name: 'test-file-input' }));
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, 'input[type="file"][name="test-file-input"]')).to.have.length(1);
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, '[class="my-dropzone"][name="test-file-input"]')).to.have.length(0);
    });

    it('does not apply the name prop if name is falsey', function () {
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { className: 'my-dropzone', name: '' }));
      _chai.expect(_reactTestutilsAdditions2['default'].find(component, 'input[type="file"][name]')).to.have.length(0);
    });

    it('overrides onClick', function () {
      var clickSpy = _sinon.spy();
      var component = _reactTestutilsAdditions2['default'].renderIntoDocument(_react2['default'].createElement(_index2['default'], { id: 'example', onClick: clickSpy }));
      var content = _reactTestutilsAdditions2['default'].find(component, '#example')[0];

      _reactTestutilsAdditions2['default'].Simulate.click(content);
      _chai.expect(clickSpy).to.not.be.called;
    });
  });
});