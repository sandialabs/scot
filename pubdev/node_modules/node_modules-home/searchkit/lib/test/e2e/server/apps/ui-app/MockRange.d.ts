import * as React from "react";
import { Panel, RangeSlider } from "../../../../../src";
export declare class MockRange extends React.Component<any, any> {
    constructor(props: any);
    static defaultProps: {
        rangeComponent: typeof RangeSlider;
        containerComponent: typeof Panel;
    };
    static propTypes: {
        containerComponent: React.Requireable<any>;
        rangeComponent: React.Requireable<any>;
    };
    render(): React.ReactElement<any>;
}
