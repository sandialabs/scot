
// This uses the ES6 proxy mechanism to implement a transparent
// scope-like copy-on-write for the context. The idea is that values
// are transparently fetched from older contexts for read, but if a
// write happens the new value is kept local. When the scope exits,
// the previous value is automatically restored. Writes will be saved
// in the object passed in via 'data'. Pass the current scope in as
// parent, or leave it blank for the root scope.
function newscope(data,parent){
    var handler = {
        get(t,k){ 
          console.info("Get ");
          if(t.hasOwnProperty(k))
            return t[k];
          else if(parent)
            return parent[k];
        }
    };
    return new Proxy(data,handler);
}

module.exports={newscope: newscope};
