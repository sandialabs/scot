print("Dropping collections...");
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
print ("Creating indexes...");
load("../../bin/database/indexes.js");
print ("Zero-ing the nexid collection...");
load("../../bin/database/zero_nextid.js");

print ("Clearing config and re-creating...");
db.config.drop();
db.scotmod.drop();
