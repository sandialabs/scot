var gulp = require('gulp');
var rename = require('gulp-rename');
var browserify = require('browserify');
var babelify = require('babelify');
var source = require('vinyl-source-stream');
var sass = require( 'gulp-sass' );
var sourcemaps = require( 'gulp-sourcemaps' );
var bulkSass = require( 'gulp-sass-bulk-import' );
var gutil = require( 'gulp-util' );
var minify = require('gulp-minify');

var paths = {
	scripts: './jsdev/react_components/**/*.jsx',
	admin: './jsdev/react_components/administration/**/*.jsx',
	sass: './sass/**/*.scss',
	build: './build/',
    buildFinal: '../public/',
	scot: '/opt/scot/public/',
}

gulp.task('watch', ['build'], function () {
    gulp.watch( paths.admin, ['buildadmin'] );
    gulp.watch( paths.scripts, ['scripts'] );
	gulp.watch( paths.sass, ['sass'] );
});

gulp.task('watch-prod', ['build-prod'], function () {
    gulp.watch( paths.admin, ['buildadmin'] );
    gulp.watch( paths.scripts, ['scripts-prod'] );
	gulp.watch( paths.sass, ['sass'] );
});

gulp.task( 'scripts', function() {
    browserify({entries: './jsdev/react_components/main/index.jsx', extensions: ['.jsx','.coffee'], debug: true}) 
    .transform('coffeeify', {only: './jsdev/react_components/components/visualization'})
    .transform('babelify', {presets: ['es2015', 'react', 'stage-2', 'stage-0']})
    .bundle()
    .on('error', err => {
        gutil.log('Browserify Error: ', gutil.colors.red(err.message))
        this.emit('end');
    })
    .pipe(source('scot.js'))
    .pipe(gulp.dest( paths.build ),{overwrite:true})
    .pipe(gulp.dest( paths.buildFinal), {overwrite: true});
    return console.log('Compiling SCOT... wait for the auto copy to complete');
} );

gulp.task( 'scripts-prod', function() {
    browserify({entries: './jsdev/react_components/main/index.jsx', extensions: ['.jsx','.coffee'], debug: true})
    .transform('coffeeify', {only: './jsdev/react_components/components/visualization'})
    .transform('babelify', {presets: ['es2015', 'react', 'stage-2', 'stage-0']})
    .bundle()
    .on('error', err => {
        gutil.log('Browserify Error: ', gutil.colors.red(err.message))
        this.emit('end');
    })
    .pipe(source('scot.js'))
    .pipe(gulp.dest( paths.build ),{overwrite:true})
    
    //minify and copy to public
    gulp.src('./build/scot.js')
    .pipe(minify({
        ext: {
            src: '-debug.js',
            min: '.js'
        }
    }))
    .pipe(gulp.dest( paths.buildFinal ))
    return console.log('Compiling SCOT... wait for the auto copy to complete');
});

gulp.task('buildadmin', function() {
    browserify({entries: './jsdev/react_components/administration/api.jsx', extensions: ['.jsx'], debug: true})
    .transform('babelify', {presets: ['es2015', 'react', 'stage-2', 'stage-0']})
    .bundle()
    .on('error', err => {
        gutil.log('Browserify Error: ', gutil.colors.red(err.message))
        this.emit('end');
    })
    .pipe(source('api.js'))
    .pipe(gulp.dest('../public/admin/'),{overwrite:true});
    return console.log('Compiling admin page... wait for the auto copy to complete');
});

gulp.task( 'sass', function() {
	return gulp.src( './sass/styles.scss' )
      .pipe( bulkSass() )
	  .pipe( sourcemaps.init() )
	  .pipe( sass().on( 'error', sass.logError ) )
	  .pipe( sourcemaps.write() )
	  .pipe( gulp.dest( paths.buildFinal +'css' ), { overwrite: true } );
} );

gulp.task( 'copy-changed', function() {
	console.log( "REMINDER: Run as 'sudo -E gulp watch-copy'" );
    return gulp.watch( paths.buildFinal +'**/*', function( obj ) {
            if ( obj.type === 'changed' ) {
                setTimeout( function() {
                    gulp.src( obj.path, { base: paths.buildFinal } )
                    .pipe( gulp.dest( paths.scot ) );
                    console.log( 'Copied', obj.path, 'to', paths.scot, '\x07' );
                }
                , 1000)
            }
    } ); 
});

gulp.task( 'set-prod', function() {
    process.env.NODE_ENV = 'production';
});


gulp.task( 'watch-copy', [ 'copy-changed', 'watch'], function() {} );

gulp.task( 'watch-copy-prod', [ 'copy-changed', 'set-prod', 'watch-prod' ], function() {} );

gulp.task( 'build', ['scripts', 'sass', 'buildadmin'] );

gulp.task( 'build-prod', ['scripts-prod', 'sass', 'buildadmin'] );

gulp.task('default', ['watch']);
