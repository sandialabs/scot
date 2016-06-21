import * as React from "react";
export declare class MovieHitsCell extends React.Component<any, {}> {
    render(): JSX.Element;
}
export declare class HitsTable extends React.Component<any, {}> {
    constructor(props: any);
    renderHeader(column: any, idx: any): JSX.Element;
    renderCell(hit: any, column: any, idx: any): any;
    render(): JSX.Element;
}
