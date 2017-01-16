var oneDay = 24 * 60 * 60 * 1000;
var d1, d2;

d1 = new Date(2012,0,1);
d2 = new Date(2012,0,1);

console.log(d1.getTime()+"\t"+d2.getTime());
while (d1.getDate() === d2.getDate()) {
    d1 = new Date(d1.getTime() + oneDay);
    d2 = new Date(d2);
    d2.setDate(d2.getDate() + 1);
    console.log(d1.getDate()+"\t"+d1.getTime()+"\t"+d2.getDate()+"\t"+d2.getTime());
}
