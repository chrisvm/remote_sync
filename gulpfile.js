var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    path = require('path'),
    gutil = require('gulp-util'),
    del = require('del'),
    vinylPaths = require('vinyl-paths');

var source = './coffee/**/*.coffee',
    dest = './build';

gulp.task('default', ['clean-coffee', 'make-coffee']);

gulp.task('make-coffee', function() {
    return gulp.src(source)
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest(output));
});

gulp.task('clean-coffee', function () {
    return gulp.src(path.join(dest, '*'))
        .pipe(del);
});

gulp.task('watch-coffee', function () {
    var output;
    for (var src in src_folders) {
        gulp.watch(src, function () {

        });
});
