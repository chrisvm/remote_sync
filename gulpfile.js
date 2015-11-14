var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    path = require('path'),
    gutil = require('gulp-util'),
    del = require('del'),
    vinylPaths = require('vinyl-paths'),
    newer = require('gulp-newer'),
    fs = require('fs');


var source = './coffee/**/*.coffee',
    dest = './build';

gulp.task('default', ['clean-coffee', 'make-coffee', 'watch-coffee']);

gulp.task('make-coffee', function() {
    return gulp.src(source)
        .pipe(newer({
            dest: dest,
            ext: '.js'
        }))
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest(dest));
});

gulp.task('clean-coffee', function () {
    gulp.src(dest)
        .pipe(vinylPaths(del));
});

gulp.task('watch-coffee', function () {
    gulp.watch(source, ['make-coffee']);
});
