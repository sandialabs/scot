import * as React from "react";
import { SearchkitComponent, SearchkitComponentProps, ReactComponentType } from "../../../../core";
export interface HitsStatsDisplayProps {
    bemBlocks: {
        container: Function;
    };
    resultsFoundLabel: string;
    timeTaken: string;
    hitsCount: string | number;
    translate: Function;
}
export interface HitsStatsProps extends SearchkitComponentProps {
    component?: ReactComponentType<HitsStatsDisplayProps>;
    countFormatter?: (count: number) => number | string;
}
export declare class HitsStats extends SearchkitComponent<HitsStatsProps, any> {
    static translations: any;
    translations: any;
    static propTypes: any;
    static defaultProps: {
        component: (props: HitsStatsDisplayProps) => JSX.Element;
        countFormatter: any;
    };
    defineBEMBlocks(): {
        container: string;
    };
    render(): React.ReactElement<any>;
}
