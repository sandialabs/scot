import * as React from "react";
export interface TogglePanelProps extends React.Props<TogglePanel> {
    key?: any;
    title?: string;
    mod?: string;
    disabled?: boolean;
    className?: string;
    collapsable?: boolean;
    rightComponent: any;
}
export declare class TogglePanel extends React.Component<TogglePanelProps, {
    collapsed: boolean;
}> {
    static propTypes: {
        title: React.Requireable<any>;
        disabled: React.Requireable<any>;
        mod: React.Requireable<any>;
        className: React.Requireable<any>;
        collapsable: React.Requireable<any>;
    };
    static defaultProps: {
        disabled: boolean;
        collapsable: boolean;
        mod: string;
    };
    constructor(props: any);
    toggleCollapsed(): void;
    componentDidMount(): void;
    componentWillUnmount(): void;
    render(): JSX.Element;
}
