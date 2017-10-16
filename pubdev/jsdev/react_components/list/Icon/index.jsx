import React from 'react';

const Icon = ({icon, ...otherProps}) => (
    <i className={'fa fa-' + icon } aria-hidden='true' {...otherProps} />
)

export default Icon
