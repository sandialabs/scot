import { ReportWidgets } from "../report";
import { Widgets as ThingWidgets } from "../thinglist";

export const Widgets = {
  ...ThingWidgets(),
  ...ReportWidgets()
};
