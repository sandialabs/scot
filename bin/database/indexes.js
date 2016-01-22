db.alertgroup.ensureIndex(  { "id":          1} );
db.alertgroup.ensureIndex(  { "message_id":  1} );
db.alertgroup.ensureIndex(  { "updated":     1} );

db.alert.ensureIndex(       { "id":         1}  );
db.alert.ensureIndex(       { "alertgroup": 1}  );
db.alert.ensureIndex(       { "updated":    1}  );
db.alert.ensureIndex(       { "when":       1}  );

db.audit.ensureIndex(       { "id":         1}  );
db.audit.ensureIndex(       { "when":       1}  );

db.checklist.ensureIndex(   { "id":         1}  );

db.event.ensureIndex(       { "id":         1}  );
db.event.ensureIndex(       { "when":       1}  );
db.event.ensureIndex(       { "subject":    1}  );

db.entity.ensureIndex(      { "id":         1}  );
db.entity.ensureIndex(      { "value":      1}  );
db.entity.ensureIndex(      { "targets":    1}  );

db.file.ensureIndex(        { "id":         1}  );
db.file.ensureIndex(        { "filename":   1}  );
db.file.ensureIndex(        { "entry":      1}  );
db.file.ensureIndex(        { "md5":        1}  );
db.file.ensureIndex(        { "sha1":       1}  );
db.file.ensureIndex(        { "sha256":     1}  );

db.history.ensureIndex(     { "id":         1}  );
db.history.ensureIndex(     { "when":       1}  );
db.history.ensureIndex(     { "who":        1}  );
db.history.ensureIndex(     { "targets":    1}  );

db.incident.ensureIndex(    {"id":          1}  );
db.incident.ensureIndex(    {"when":        1}  );
db.incident.ensureIndex(    {"subject":     1}  );

db.intel.ensureIndex(       { "id":         1}  );
db.intel.ensureIndex(       { "when":       1}  );
db.intel.ensureIndex(       { "subject":    1}  );

db.source.ensureIndex(      { "id":         1}  );
db.source.ensureIndex(      { "value":      1}  );
db.source.ensureIndex(      { "targets":    1}  );

db.tag.ensureIndex(         { "id":         1}  );
db.tag.ensureIndex(         { "value":      1}  );
db.tag.ensureIndex(         { "targets":    1}  );

