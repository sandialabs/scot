db.alerts.ensureIndex(      {alert_id: 1});
db.alerts.ensureIndex(      {alertgroup: 1});
db.alerts.ensureIndex(      {searchtext: 1});
db.alerts.ensureIndex(      {created: 1});
db.alerts.ensureIndex(      {updated: 1});

db.alertgroups.ensureIndex( {alertgroup_id: 1});
db.alertgroups.ensureIndex( {created: 1});
db.alertgroups.ensureIndex( {updated: 1});
db.alertgroups.ensureIndex( {view_count: 1});
db.alertgroups.ensureIndex( {view_count: -1});

db.alert_types.ensureIndex( {alert_tyep_id: 1});

db.audits.ensureIndex(      {when: 1});

db.checklists.ensureIndex(  {checklist_id: 1});

db.entries.ensureIndex(     {entry_id: 1});
db.entries.ensureIndex(     {target_id: 1, target_type: 1});
db.entries.ensureIndex(     {created: 1});
db.entries.ensureIndex(     {updated: 1});

db.events.ensureIndex(      {event_id: 1});
db.events.ensureIndex(      {created: 1});
db.events.ensureIndex(      {updated: 1});

db.files.ensureIndex(       {file_id: 1});
db.files.ensureIndex(       {target_type: 1});
db.files.ensureIndex(       {target_id: 1});
db.files.ensureIndex(       {entry_id: 1});

db.incidents.ensureIndex(   {incident_id: 1});
db.incidents.ensureIndex(      {created: 1});
db.incidents.ensureIndex(      {updated: 1});

db.users.ensureIndex(       {username: 1});

db.tags.ensureIndex(        {taggee: 1});
db.tags.ensureIndex(        {text: 1});

