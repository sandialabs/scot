import { ReportWidgets } from '../report';
import Status from '../status';
import ThingList from '../thinglist';

export const Widgets = {
	intel: {
		type: ThingList,
		title: "Thing List",
		description: "A list of things",
		props: {
			thingType: 'intel',
			title: 'Top Intel',
		}
	},
	events: {
		type: ThingList,
		title: "Thing List2",
		description: "A list of things",
		props: {
			thingType: 'event',
			title: 'Top Events',
		}
	},
	...ReportWidgets(),
};
