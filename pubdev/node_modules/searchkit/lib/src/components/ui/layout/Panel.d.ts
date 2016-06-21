import * as React from "react";
export interface PanelProps extends React.Props<Panel> {
    key?: any;
    title?: string;
    mod?: string;
    disabled?: boolean;
    className?: string;
    collapsable?: boolean;
    defaultCollapsed?: boolean;
}
export declare class Panel extends React.Component<PanelProps, {
    collapsed: boolean;
}> {
    static propTypes: {
        title: React.Requireable<any>;
        disabled: React.Requireable<any>;
        mod: React.Requireable<any>;
        className: React.Requireable<any>;
        collapsable: React.Requireable<any>;
        defaultCollapsed: React.Requireable<any>;
    };
    static defaultProps: {
        disabled: boolean;
        collapsable: boolean;
        defaultCollapsed: boolean;
        mod: string;
    };
    constructor(props: any);
    componentWillReceiveProps(nextProps: any): void;
    toggleCollapsed(): void;
    render(): JSX.Element;
}
