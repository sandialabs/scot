db.alerts.drop();
db.alertgroups.drop();
db.deleted_alerts.drop();
db.entries.drop();
db.deleted_entries.drop();
db.events.drop();
db.deleted_events.drop();
db.incidents.drop();
db.deleted_incidents.drop();

db.events.ensureIndex({"event_id": 1});

db.alerts.ensureIndex({"updated": 1, "alert_id": 1});
db.alerts.ensureIndex({"alert_id":1});
db.alerts.ensureIndex({"alertref":1});

db.alertgroups.ensureIndex({"alertgroup_id": 1});
db.alertgroups.ensureIndex({"alert_ids": 1});

db.entries.ensureIndex({"entry_id": 1});
db.entries.ensureIndex({"entry_id" :1});
db.entries.ensureIndex({"target_id": 1, "target_type": 1});

db.checklists.drop();
db.checklists.ensureIndex({"checklist_id": 1});

db.files.drop();
db.files.ensureIndex({"file_id": 1});

db.alert_types.drop();
db.alert_types.ensureIndex({"alert_type_id": 1});

db.idgenerators.drop();

db.tags.drop();
db.tags.ensureIndex({taggee: 1});
db.tags.ensureIndex({text: 1});

db.users.drop();

db.entities.drop();
db.entities.ensureIndex({entity_id: 1});
db.entities.ensureIndex({entity_type: 1, value: 1});
db.entities.ensureIndex({entries:1});
db.entities.ensureIndex({events:1});
db.entities.ensureIndex({alerts:1});
db.entities.ensureIndex({incidents:1});

db.idgenerators.insert({"collection": "alerts", "lastid": 0});
db.idgenerators.insert({"collection": "entries", "lastid": 0});
db.idgenerators.insert({"collection": "events", "lastid": 0});
db.idgenerators.insert({"collection": "incidents", "lastid": 0});
db.idgenerators.insert({"collection": "checklists", "lastid": 0});
db.idgenerators.insert({"collection": "files", "lastid": 0});
db.idgenerators.insert({"collection": "alert_types", "lastid": 0});
db.idgenerators.insert({"collection": "alertgroup", "lastid": 0});
