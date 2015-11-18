require('coffee-script/register');
var explode = require('./explode');

(function () {
    var callback = function (all) {
        console.log(all);
    };
    process.stdin
        .pipe(explode('\n', callback));
})();
