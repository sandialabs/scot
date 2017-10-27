# react-tinymce

React TinyMCE component

## Installing

```bash
$ npm install react-tinymce
```

## Demo

http://instructure-react.github.io/react-tinymce/

## Example

```js
import React from 'react';
import ReactDOM from 'react-dom';
import TinyMCE from 'react-tinymce';

const App = React.createClass({
  handleEditorChange(e) {
    console.log(e.target.getContent());
  },

  render() {
    return (
      <TinyMCE
        content="<p>This is the initial content of the editor</p>"
        config={{
          plugins: 'autolink link image lists print preview',
          toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'
        }}
        onChange={this.handleEditorChange}
      />
    );
  }
});

ReactDOM.render(<App/>, document.getElementById('container'));
```

## Dependency

This component depends on `tinymce` being globally accessible.

```html
<script src="//tinymce.cachefly.net/4.2/tinymce.min.js"></script>
```

## Contributing

install your dependencies:

`npm install`

rackt-cli depends on a version of babel-eslint that will not run successfully with
the rest of this project.  Until an upgrade is available, after installing,
edit "node_modules/rackt-cli/package.json"
and update it's babel-eslint to at least 4.1.7. Then `npm install` in the rackt
directory, and return to project root.  From here on you need to use the
rackt version in node modules, so either alias "rackt" to it's bin, or
just path each command into node_modules/.bin like below.

To make sure the linter is happy and the functional tests run, execute:

`./node_modules/.bin/rackt test`

To release, use `./node_modules/.bin/rackt release`

## License

MIT
