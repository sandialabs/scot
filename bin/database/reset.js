db.alert.drop();
db.alertgroup.drop();
db.audit.drop();
db.checklist.drop();
db.config.drop();
db.entity.drop();
db.entry.drop();
db.event.drop();
db.file.drop();
db.history.drop();
db.incident.drop();
db.intel.drop();
db.nextid.drop();
db.scotmod.drop();
db.source.drop();
db.tag.drop();
db.users.drop();

load("./config.js");
load("./indexes.js");
load("./zero_nextid.js");



