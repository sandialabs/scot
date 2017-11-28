db.dropDatabase();
db.nextid.insert({"collection": "alert",      "lastid": 0});
db.nextid.insert({"collection": "alertgroup", "lastid": 0});
db.nextid.insert({"collection": "audit",      "lastid": 0});
db.nextid.insert({"collection": "checklist",  "lastid": 0});
db.nextid.insert({"collection": "config",     "lastid": 0});
db.nextid.insert({"collection": "deleted",    "lastid": 0});
db.nextid.insert({"collection": "entity",     "lastid": 0});
db.nextid.insert({"collection": "entry",      "lastid": 0});
db.nextid.insert({"collection": "event",      "lastid": 0});
db.nextid.insert({"collection": "file",       "lastid": 0});
db.nextid.insert({"collection": "guide",      "lastid": 0});
db.nextid.insert({"collection": "handler",    "lastid": 0});
db.nextid.insert({"collection": "incident",   "lastid": 0});
db.nextid.insert({"collection": "intel",      "lastid": 0});
db.nextid.insert({"collection": "module",     "lastid": 2});
db.nextid.insert({"collection": "tag",        "lastid": 0});
db.nextid.insert({"collection": "user",       "lastid": 0});

db.module.insert({
    "id":           1,
    "mode":         "dev",
    "class":        "Scot::Util::EntityExtractor",
    "attribute":    "entity_extractor"
});
db.module.insert({
    "id":           2,
    "mode":         "dev",
    "class":        "Scot::Util::Activemq",
    "attribute":    "activemq",
});
