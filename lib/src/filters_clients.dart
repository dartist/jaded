//ignore_for_file: unused_element
part of jaded;

var _clientFilters = <String, Function>{};

dynamic _clientFilter(String name, String str, Map options) {
  var res;
  if (_clientFilters[name] is Function){
    res = _clientFilters[name](str, options);}
  else{
    throw ParseError('unknown filter ":$name"');}

  return res;
}

bool _clientFilterExists(String name, [String str, Map options]) =>
    _clientFilters[name] is Function;
