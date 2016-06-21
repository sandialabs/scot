import * as React from "react";
import { SearchkitComponent, SearchkitComponentProps } from "../../../../core";
export interface TagFilterProps extends SearchkitComponentProps {
    field: string;
    value: string;
    children?: React.ReactChildren;
}
export declare class TagFilter extends SearchkitComponent<TagFilterProps, any> {
    constructor();
    isActive(): any;
    handleClick(): void;
    render(): JSX.Element;
}
