import * as React from "react";
import { SearchkitComponent, PageSizeAccessor, SearchkitComponentProps, ReactComponentType, SourceFilterType, HitsAccessor, RenderComponentType } from "../../../../core";
export interface HitItemProps {
    key: string;
    bemBlocks?: any;
    result: any;
}
export declare class HitItem extends React.Component<HitItemProps, any> {
    render(): JSX.Element;
}
export interface HitsListProps {
    mod?: string;
    className?: string;
    itemComponent?: RenderComponentType<HitItemProps>;
    hits: Array<Object>;
}
export declare class HitsList extends React.Component<HitsListProps, any> {
    static defaultProps: {
        mod: string;
        itemComponent: typeof HitItem;
    };
    static propTypes: {
        mod: React.Requireable<any>;
        className: React.Requireable<any>;
        itemComponent: React.Requireable<any>;
        hits: React.Requireable<any>;
    };
    render(): JSX.Element;
}
export interface HitsProps extends SearchkitComponentProps {
    hitsPerPage: number;
    highlightFields?: Array<string>;
    sourceFilter?: SourceFilterType;
    itemComponent?: ReactComponentType<HitItemProps>;
    listComponent?: ReactComponentType<HitsListProps>;
    scrollTo?: boolean | string;
}
export declare class Hits extends SearchkitComponent<HitsProps, any> {
    hitsAccessor: HitsAccessor;
    static propTypes: any;
    static defaultProps: {
        listComponent: typeof HitsList;
        scrollTo: string;
    };
    componentWillMount(): void;
    defineAccessor(): PageSizeAccessor;
    render(): React.ReactElement<any>;
}
