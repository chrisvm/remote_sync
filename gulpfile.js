var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    path = require('path'),
    gutil = require('gulp-util'),
    del = require('del'),
    vinylPaths = require('vinyl-paths');


gulp.task('coffee', function() {
    var src_folders = {
        './coffee': './build/',
        './coffee/config': './build/config'
    };

    var output;
    for (var src in src_folders) {
        output = src_folders[src];
        src = path.join(src, '*.coffee');
        gulp.src(src)
            .pipe(coffee({bare: true}).on('error', gutil.log))
            .pipe(gulp.dest(output));
    }
});
