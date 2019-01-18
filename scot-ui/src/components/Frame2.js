import React from 'react'
import ReactDOM from 'react-dom';

class Frame2 extends React.Component {
    componentWillReceiveProps(nextProps) {
        if (nextProps.styleSheets.join('') !== this.props.styleSheets.join('')) {
            this.updateStylesheets(nextProps.styleSheets);
        }

        if (nextProps.css !== this.props.css) {
            this.updateCss(nextProps.css);
        }

        const frame = ReactDOM.findDOMNode(this);
        ReactDOM.render(
            nextProps.children,
            frame.contentDocument.getElementById('root')
        );
    }

    componentDidMount() {
        setTimeout(this.renderFrame.bind(this), 0);
    }

    componentWillUnmount() {
        ReactDOM.unmountComponentAtNode(
            ReactDOM.findDOMNode(this).contentDocument.getElementById('root')
        );
    }

    updateStylesheets(styleSheets) {
        const links = this.head.querySelectorAll('link');
        for (let i = 0, l = links.length; i < l; i++) {
            const link = links[i];
            link.parentNode.removeChild(link);
        }

        if (styleSheets && styleSheets.length) {
            styleSheets.forEach(href => {
                const link = document.createElement('link');
                link.setAttribute('rel', 'stylesheet');
                link.setAttribute('type', 'text/css');
                link.setAttribute('href', href);
                this.head.appendChild(link);
            });
        }
    }


    renderFrame() {
        const { styleSheets, css } = this.props;
        const frame = ReactDOM.findDOMNode(this);
        const root = document.createElement('div');

        root.setAttribute('id', 'root');

        this.head = frame.contentDocument.head;
        this.body = frame.contentDocument.body;
        this.body.appendChild(root);

        this.updateStylesheets(styleSheets);

        ReactDOM.render(this._children, root);
    }

    render() {
        this._children = this.props.children;
        // render children manually
        const { children, styleSheets, css, ...leftover } = this.props;
        return < iframe style={{ width: "100%", height: this.state.height }} {...leftover} onLoad={this.renderFrame} />;
    }
}

module.exports = Frame2;