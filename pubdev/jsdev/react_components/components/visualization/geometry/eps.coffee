# fuzzy comparison functions
feps=  0.0000001
feq=   (a,b) -> (Math.abs (a-b)) < feps
fgt=   (a,b) -> (a-b) > feps
fgte=  (a,b) -> ((a-b) > feps) or (feq a,b)
flt=   (a,b) -> fgt b,a
flte=  (a,b) -> (fgte b,a)
fnz=   (a) -> not fzero a
fzero= (a) -> feq a,0
 
module.exports = 
    feps: feps
    feq: feq
    fgt: fgt
    fgte: fgte
    flt: flt
    flte: flte
    fnz: fnz
    fzero: fzero
    
        
