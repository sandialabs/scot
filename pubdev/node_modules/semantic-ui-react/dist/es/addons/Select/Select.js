import _extends from 'babel-runtime/helpers/extends';
import React from 'react';

import { META } from '../../lib';
import Dropdown from '../../modules/Dropdown';

/**
 * A Select is sugar for <Dropdown selection />.
 * @see Dropdown
 * @see Form
 */
function Select(props) {
  return React.createElement(Dropdown, _extends({}, props, { selection: true }));
}

Select.handledProps = [];
Select._meta = {
  name: 'Select',
  type: META.TYPES.ADDON
};

Select.Divider = Dropdown.Divider;
Select.Header = Dropdown.Header;
Select.Item = Dropdown.Item;
Select.Menu = Dropdown.Menu;

export default Select;