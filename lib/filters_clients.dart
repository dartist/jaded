part of jaded;

var clientFilters = new Map<String,Function>();

dynamic clientFilter(String name, String str, Map options){
  var res;
  if (clientFilters[name] is Function)
    res = clientFilters[name](str, options);
  else
    throw new ParseError('unknown filter ":$name"');

  return res;
}

clientFilterExists(String name, [String str, Map options]) =>
    clientFilters[name] is Function;

