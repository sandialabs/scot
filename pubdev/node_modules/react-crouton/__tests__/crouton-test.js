// __test__/crouton-test.js

jest.dontMock('../index.js')

var React = require('react')
var Crouton = React.createFactory(require('../index.js'))
var TestUtils = require('react-addons-test-utils')

describe('Crouton', function () {

  it('should render a simple crouton', function () {

    // Render a crouton with message and type
    var data = {
      id: 123213,
      message: 'simple',
      type: 'error',
      hidden: false
    }
    var crouton = TestUtils.renderIntoDocument(
      Crouton({
        id: data.id,
        message: data.message,
        type: data.type,
        hidden: data.hidden
      }))
      // Verify crouton hidden false
    var pdiv = TestUtils.findRenderedDOMComponentWithClass(crouton, 'crouton')
    expect(pdiv.hidden, false)
      // Verify textContent
    var cdiv = TestUtils.findRenderedDOMComponentWithClass(crouton, data.type)
    expect(cdiv.textContent, data.message)
      // Verify has a child span
    var spans = cdiv.getElementsByTagName('span')
    expect(spans.length, 1)
    expect(spans[0], data.message)
      // No buttons
    expect(cdiv.getElementsByTagName('button'), [])
      // Crouton will hidden after 2000 ms default
    runs(function () {
      setTimeout(function () {
        expect(pdiv.hidden, true)
      }, 2000)
    })
  })

  it('should render an message array', function () {
    // Render a crouton with message and type
    var data = {
      id: 123213,
      message: ['simple', 'message'],
      type: 'error',
      hidden: false
    }
    var crouton = TestUtils.renderIntoDocument(
      Crouton({
        id: data.id,
        message: data.message,
        type: data.type,
        hidden: data.hidden
      }))
    var pdiv = TestUtils.findRenderedDOMComponentWithClass(crouton, 'crouton')
    var cdiv = TestUtils.findRenderedDOMComponentWithClass(crouton, data.type)
      // Verify has a child span
    var spans = cdiv.getElementsByTagName('span')
    expect(spans.length, 2)
    data.message.forEach(function (msg, i) {
      expect(spans[i], data.message[i])
    })
    var done = false
      // Crouton will hidden after 2000 ms default
    runs(function () {
      setTimeout(function () {
        expect(pdiv.hidden, true)
      }, 2000)
    })
  })
})
