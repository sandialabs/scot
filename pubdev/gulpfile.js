var gulp = require('gulp');
var browserify = require('browserify');
var babelify = require('babelify');
var source = require('vinyl-source-stream');
var sass = require( 'gulp-sass' );
var sourcemaps = require( 'gulp-sourcemaps' );
var bulkSass = require( 'gulp-sass-bulk-import' );


var paths = {
	scripts: './jsdev/react_components/**/*.jsx',
	admin: './jsdev/react_components/administration/**/*.jsx',
	sass: './sass/**/*.scss',
	build: '../public/',
	scot: '/opt/scot/public/',
}

// gulp.task('watch', ['build','buildadmin'], function () {
gulp.task('watch', ['build'], function () {
    gulp.watch( paths.admin, ['buildadmin'] );
    gulp.watch( paths.scripts, ['scripts'] );
	gulp.watch( paths.sass, ['sass'] );
});

gulp.task( 'scripts', function() {
  return browserify({entries: './jsdev/react_components/main/index.jsx', extensions: ['.jsx','.coffee'], debug: true})
    .transform('coffeeify', {only: './jsdev/react_components/components/visualization'})
    .transform('babelify', {presets: ['es2015', 'react', 'stage-2', 'stage-0']})
    .bundle()
    .pipe(source('scot-3.5.js'))
    .pipe(gulp.dest( paths.build ),{overwrite:true});
} );

gulp.task('buildadmin', function() {
    return browserify({entries: './jsdev/react_components/administration/api.jsx', extensions: ['.jsx'], debug: true})
    .transform('babelify', {presets: ['es2015', 'react', 'stage-2', 'stage-0']})
    .bundle()
    .pipe(source('api.js'))
    .pipe(gulp.dest('../public/admin/'),{overwrite:true});
});

gulp.task( 'sass', function() {
	return gulp.src( './sass/styles.scss' )
	  .pipe( bulkSass() )
	  .pipe( sourcemaps.init() )
	  .pipe( sass().on( 'error', sass.logError ) )
	  .pipe( sourcemaps.write() )
	  .pipe( gulp.dest( paths.build +'css' ), { overwrite: true } );
} );

gulp.task( 'watch-copy', ['watch'], function() {
	console.log( "REMINDER: Run as 'sudo -E gulp watch-copy'" );
	return gulp.watch( paths.build +'**/*', function( obj ) {
			if ( obj.type === 'changed' ) {
				setTimeout( function() {
                    gulp.src( obj.path, { base: paths.build } )
					.pipe( gulp.dest( paths.scot ) );
				    console.log( 'Copied', obj.path, 'to', paths.scot, '\x07' );
			    }
                , 1000) 
            }
	} );
} );

gulp.task( 'build', ['scripts', 'sass', 'buildadmin'] );

gulp.task('default', ['watch']);
