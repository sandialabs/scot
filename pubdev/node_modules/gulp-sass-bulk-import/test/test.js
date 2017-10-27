var expect = require('expect.js');
var vinyl = require('vinyl-fs');
var bulkSass = require('..');


describe('gulp-sass-glob-import', function() {

    it('should parse a single directory', function(done) {
        var equalString = '@import "' + __dirname + '/test-scss/import-folder/f1.scss' + '";\n';
        equalString += '@import "' + __dirname + '/test-scss/import-folder/f2.scss' + '";\n';

        vinyl
            .src(__dirname + '/test-scss/app.scss')
            .pipe(bulkSass())
            .on('data', function(file) {
                expect(file.contents.toString('utf-8').trim()).to.equal(equalString.trim());
            })
            .on('end', function() {
                done();
            });
    });


    it('should parse a directory recursively', function(done) {
        var equalString = '@import "' + __dirname + '/test-scss/recursive-folder/f1.scss' + '";\n';
        equalString += '@import "' + __dirname + '/test-scss/recursive-folder/f2.scss' + '";\n';
        equalString += '@import "' + __dirname + '/test-scss/recursive-folder/nested-folder/f3.scss' + '";\n';

        vinyl
            .src(__dirname + '/test-scss/recursive.scss')
            .pipe(bulkSass())
            .on('data', function(file) {
                expect(file.contents.toString('utf-8').trim()).to.equal(equalString.trim());
            })
            .on('end', function() {
                done();
            });
    });


    it('should handle single and double quotes', function(done) {
        var equalString = '@import "' + __dirname + '/test-scss/import-folder/f1.scss' + '";\n';
        equalString += '@import "' + __dirname + '/test-scss/import-folder/f2.scss' + '";\n\n';
        equalString += '@import "' + __dirname + '/test-scss/recursive-folder/nested-folder/f3.scss' + '";\n';

        
        vinyl
            .src(__dirname + '/test-scss/single-double-quotes.scss')
            .pipe(bulkSass())
            .on('data', function(file) {
                expect(file.contents.toString('utf-8').trim()).to.equal(equalString.trim());
            })
            .on('end', function() {
                done();
            });
    });

    it('should not include a stylesheet more than once', function(done){
      var equalString = '@import "duplicate-folder/f1";\n';
      equalString +=    '@import "' + __dirname + '/test-scss/duplicate-folder/f2.scss";\n';
      equalString +=    '@import "' + __dirname + '/test-scss/duplicate-folder/f3.scss";\n';

      vinyl
          .src(__dirname + '/test-scss/duplicates.scss')
          .pipe(bulkSass())
          .on('data', function(file){
            expect(file.contents.toString('utf-8').trim()).to.equal(equalString.trim());
          })
          .on('end', function(){
            done();
          });
    });

    it('alternate: should not include a stylesheet more than once', function(done){
      var equalString = '@import "duplicate-folder/f1"' + ';\n';
      equalString +=    '@import "duplicate-folder/f2"' + ';\n';
      equalString +=    '@import "' + __dirname + '/test-scss/duplicate-folder/f3.scss' + '";\n';

      vinyl
          .src(__dirname + '/test-scss/duplicates2.scss')
          .pipe(bulkSass())
          .on('data', function(file){
            expect(file.contents.toString('utf-8').trim()).to.equal(equalString.trim());
          })
          .on('end', function(){
            done();
          });
    });

});