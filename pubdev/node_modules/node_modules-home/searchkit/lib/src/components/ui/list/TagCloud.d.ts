import * as React from "react";
import { ReactComponentType } from "../../../";
import { ListProps, ItemProps } from './ListProps';
export interface TagCloudProps extends ListProps {
    minFontSize?: number;
    maxFontSize?: number;
    itemComponent?: ReactComponentType<ItemProps>;
}
export declare class TagCloud extends React.Component<TagCloudProps, any> {
    static defaultProps: any;
    render(): JSX.Element;
    renderItem(item: any, bemBlocks: any, min: any, max: any): React.ReactElement<any>;
}
