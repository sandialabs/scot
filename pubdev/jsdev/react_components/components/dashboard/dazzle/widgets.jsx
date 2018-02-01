import { ReportWidgets } from '../report';
import Status from '../status';
import ThingList, { Widgets as ThingWidgets } from '../thinglist';

export const Widgets = {
	...ThingWidgets(),
	...ReportWidgets(),
};
