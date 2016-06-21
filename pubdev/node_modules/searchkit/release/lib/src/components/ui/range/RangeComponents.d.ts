import * as React from 'react';
export declare class RangeComponent extends React.Component<any, {}> {
    static propTypes: {
        showHistogram: React.Requireable<any>;
        showSlider: React.Requireable<any>;
        showInput: React.Requireable<any>;
    };
    render(): JSX.Element;
}
export declare function RangeComponentBuilder(components: any): (props: any) => JSX.Element;
export declare const RangeSliderHistogram: (props: any) => JSX.Element;
export declare const RangeSliderHistogramInput: (props: any) => JSX.Element;
export declare const RangeSliderInput: (props: any) => JSX.Element;
export declare const RangeHistogramInput: (props: any) => JSX.Element;
