import { ReportWidgets } from '../report';
import Status from '../status';
import ThingList from '../thinglist';

export const Widgets = {
	thinglist: {
		type: ThingList,
		title: "Thing List",
		description: "A list of things",
		props: {
			thingType: 'intel',
		}
	},
	...ReportWidgets(),
};
