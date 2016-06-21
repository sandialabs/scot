import * as React from "react";
export interface RangeProps {
    onChange: (range: {
        min: number;
        max: number;
    }) => void;
    onFinished: (range: {
        min: number;
        max: number;
    }) => void;
    min: number;
    max: number;
    minValue?: number;
    maxValue?: number;
    items: Array<any>;
    disabled?: boolean;
    mod?: string;
    className?: string;
    translate?: (string) => string;
}
export declare const RangePropTypes: {
    onChange: React.Validator<any>;
    onFinishd: React.Validator<any>;
    min: React.Validator<any>;
    max: React.Validator<any>;
    minValue: React.Requireable<any>;
    maxValue: React.Requireable<any>;
    items: React.Requireable<any>;
    disabled: React.Requireable<any>;
    mod: React.Requireable<any>;
    className: React.Requireable<any>;
    translate: React.Requireable<any>;
};
