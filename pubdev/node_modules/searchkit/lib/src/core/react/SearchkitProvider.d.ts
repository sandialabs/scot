import * as React from "react";
import { SearchkitManager } from "../SearchkitManager";
export interface SearchkitProps {
    searchkit: SearchkitManager;
    children?: any;
}
export declare class SearchkitProvider extends React.Component<SearchkitProps, any> {
    static childContextTypes: {
        searchkit: React.Requireable<any>;
    };
    static propTypes: {
        searchkit: React.Validator<any>;
        children: React.Validator<any>;
    };
    componentWillMount(): void;
    componentDidMount(): void;
    componentWillUnmount(): void;
    getChildContext(): {
        searchkit: SearchkitManager;
    };
    render(): any;
}
