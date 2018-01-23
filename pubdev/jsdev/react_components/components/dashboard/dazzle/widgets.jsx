import { ReportWidgets } from '../report';
import Status from '../status';

export const Widgets = {
	status: {
		type: Status,
		title: "Scot Status",
		description: "Status of SCOT services",
	},
	...ReportWidgets(),
};
