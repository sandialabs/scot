"use strict";
var ReactTestUtils = require('react-addons-test-utils');
var beautifyHtml = require('js-beautify').html;
var renderToStaticMarkup = require('react-dom/server').renderToStaticMarkup;
var ReactDOM = require("react-dom");
var compact = require("lodash/compact");
var map = require("lodash/map");
exports.hasClass = function (inst, className) {
    if (ReactTestUtils.isDOMComponent(inst.node)) {
        return inst.hasClass(className);
    }
    else {
        try {
            var classes = ReactDOM.findDOMNode(inst.node).className;
            return (' ' + classes + ' ').indexOf(' ' + className + ' ') > -1;
        }
        catch (e) { }
    }
    return false;
};
function jsxToHTML(Element) {
    return renderToStaticMarkup(Element).replace(/<input([^>]*)\/>/g, "<input$1>");
}
exports.jsxToHTML = jsxToHTML;
exports.printPrettyHtml = function (html) {
    html = beautifyHtml(html, { "indent_size": 2 })
        .replace(/class=/g, "className=")
        .replace(/<input([^>]*)>/g, "<input$1/>")
        .replace(/readonly=""/g, "readOnly={true}")
        .replace(/font-size/g, "fontSize")
        .replace(/style="([^"]+)"+/g, function (match, style) {
        var reactStyle = map(compact(style.split(";")), function (keyvalue) {
            var _a = keyvalue.split(":"), key = _a[0], value = _a[1];
            return key + ":\"" + value + "\"";
        }).join(",");
        return "style={{" + reactStyle + "}}";
    });
    console.log("\n" + html);
};
exports.fastClick = function (el) {
    el.simulate("mouseDown", { button: 0 });
};
//# sourceMappingURL=TestHelpers.js.map