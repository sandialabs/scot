module.exports = {

  buildClassName: function(baseName) {
    var name = baseName;
    if (this.props.className) {
      name += ' ' + this.props.className;
    }
    return name;
  },
};
