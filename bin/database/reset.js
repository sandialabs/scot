db.alert.drop();
db.alertgroup.drop();
db.audit.drop();
db.checklist.drop();
db.entity.drop();
db.entry.drop();
db.event.drop();
db.file.drop();
db.history.drop();
db.incident.drop();
db.intel.drop();
db.nextid.drop();
db.source.drop();
db.tag.drop();
db.users.drop();
db.link.drop();

// load("./config.js");
load("../../bin/database/indexes.js");
load("../../bin/database/zero_nextid.js");

db.config.drop();
db.scotmod.drop();
load("../../bin/database/config.DO_NOT_ADD_TO_GIT.js");



