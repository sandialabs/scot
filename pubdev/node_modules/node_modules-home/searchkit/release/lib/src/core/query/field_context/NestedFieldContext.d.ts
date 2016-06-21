import { FieldContext } from './FieldContext';
export declare class NestedFieldContext extends FieldContext {
    constructor(fieldOptions: any);
    getAggregationPath(): string;
    wrapAggregations(...aggregations: any[]): {}[];
    wrapFilter(filter: any): {
        nested: any;
    };
}
