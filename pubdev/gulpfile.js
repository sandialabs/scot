var gulp = require('gulp');
var browserify = require('browserify');
var babelify = require('babelify');
var source = require('vinyl-source-stream');

gulp.task('watch', ['build-coffee', 'build'], function () {
    gulp.watch('./jsdev/react_components/**/**', ['build-coffee']);
});

gulp.task('build-coffee'), function() {
    //build coffee code here
}

gulp.task('build', ['build-coffee'], function () {
    return browserify({entries: './jsdev/react_components/main/index.jsx', extensions: ['.jsx'], debug: true})
        .transform('babelify', {presets: ['es2015', 'react']})
        .bundle()
        .pipe(source('scot-3.5.js'))
        .pipe(gulp.dest('../public/'),{overwrite:true});
});

gulp.task('default', ['watch']);
