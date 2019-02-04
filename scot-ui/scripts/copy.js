const fs = require('fs-extra')
fs.copy('./build/', '../public', function (err) {
  if (err) {
      console.error(err);
   } else {
     console.log("success!");
   }
}); //c
