import gulp from 'gulp'
import babel from 'gulp-babel'
import mocha from 'gulp-mocha'
import watch from 'gulp-watch'
import batch from 'gulp-batch'

import { expect } from 'chai'
global.expect = expect

gulp.task('build', () =>
    gulp.src('src/**/*.js')
    .pipe(babel())
    .pipe(gulp.dest('dist'))
)

gulp.task('test', () =>
    gulp.src('test/**/*.js')
    .pipe(mocha({ globals: ['expect'] }))
)

gulp.task('test-watch', () => {
    watch(['src/**/*.js', 'test/**/*.js'], batch((events, done) => {
        gulp.start('test', done)
    }))
})
