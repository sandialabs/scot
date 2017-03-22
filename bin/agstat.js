var map = function() {
    var key = this.dow;
    var value = {
        sum: this.value,
        min: this.value,
        max: this.value,
        count: 1,
        diff: 0
    };
    emit(key, value);
};

var reduce = function(dow, value) {
    var a = value[0];
    for (var i = 1; i < value.length; i++) {
        var b = value[i];
        var delta = a.sum / a.count - b.sum / b.count;
        var weight = (a.count * b.count) / (a.count + b.count);
        a.diff += b.diff + delta * delta * weight;
        a.sum += b.sum;
        a.count += b.count;
        a.min = Math.min(a.min, b.min);
        a.max = Math.max(a.max, b.max);
    }
    return a;
}

var finalize = function(key, reducedVal) {
    reducedVal.avg  = reducedVal.sum /reducedVal.count;
    reducedVal.variance = reducedVal.diff / reducedVal.count;
    reducedVal.stddev = Math.sqrt(reducedVal.variance);
    return reducedVal;
}

db.stat.mapReduce(map, reduce, {
    out: { inline:1 },
    query: {
        metric: /alert[s]+ created/,
    },
    finalize: finalize
});
