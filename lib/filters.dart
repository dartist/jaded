part of jaded;

var filters = new Map<String,Function>();

dynamic filter(String name, String str, Map options){
  var res;
  if (filters[name] is Function)
    res = filters[name](str, options);
  else if (transformers[name] != null){
    var res = transformers[name].renderSync(str, options);
    if (transformers[name].outputFormat == 'js') {
      res = '<script type="text/javascript">\n' + res + '</script>';
    } else if (transformers[name].outputFormat == 'css') {
      res = '<style type="text/css">' + res + '</style>';
    } else if (transformers[name].outputFormat == 'xml') {
      res = res.replaceAll("'", '&#39;');
    } 
  }
  else
    throw new ParseError('unknown filter ":$name"');
 
  return res;
}

filterExists(String name, [String str, Map options]) =>
  filters[name] is Function;

