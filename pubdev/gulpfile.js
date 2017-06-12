var gulp = require('gulp');
var browserify = require('browserify');
var babelify = require('babelify');
var source = require('vinyl-source-stream');

gulp.task('watch', ['build','buildadmin'], function () {
    gulp.watch('./jsdev/react_components/**/**', ['build']);
    gulp.watch('.jsdev/react_components/administration/**',['buildadmin']);
});

gulp.task('build', function () {
  return browserify({entries: './jsdev/react_components/main/index.jsx', extensions: ['.jsx','.coffee'], debug: true})
    .transform('coffeeify', {only: './jsdev/react_components/components/visualization'})
    .transform('babelify', {presets: ['es2015', 'react']})
    .bundle()
    .pipe(source('scot-3.5.js'))
    .pipe(gulp.dest('../public/'),{overwrite:true});
});

gulp.task('buildadmin', function() {
    return browserify({entries: './jsdev/react_components/administration/api.jsx', extensions: ['.jsx'], debug: true})
    .transform('babelify', {presets: ['es2015', 'react']})
    .bundle()
    .pipe(source('api.js'))
    .pipe(gulp.dest('../public/admin/'),{overwrite:true});
});

gulp.task('default', ['watch']);
