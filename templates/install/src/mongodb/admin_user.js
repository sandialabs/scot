db.user.insert({
    "id": 1,
	"local_acct" : 1,
	"groups" : [
		"wg-scot",
		"wg-scot-admin",
		"wg-scot-ir"
	        
	],
	"tzpref" : "MST7MDT",
	"username" : "admin",
	"theme" : "default",
	"user_id" : NumberLong(1),
	"active" : 1,
	"created" : NumberLong(0),
	"updated" : NumberLong(0),
	"flair" : "on",
	"lastvisit" : NumberLong(0),
	"display_orientation" : "horizontal",
	"fullname" : "Local Admin Account",
	"last_activity_check" : 4
})
db.user.ensureIndex({username: 1});
