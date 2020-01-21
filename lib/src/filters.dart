part of jaded;

var _filters = <String, Function>{};

dynamic _filter(String name, String str, Map options) {
  var res;
  if (_filters[name] is Function) {
    res = _filters[name](str, options);
  } else if (_transformers[name] != null) {
    var transformer = _transformers[name];
    res = transformer.renderSync(str, options);
    if (transformer.outputFormat == 'js') {
      res = '<script type="text/javascript">\n$res</script>';
    } else if (transformer.outputFormat == 'css') {
      res = '<style type="text/css">$res</style>';
    } else if (transformer.outputFormat == 'xml') {
      res = res.replaceAll("'", '&#39;');
    }
  } else {
    throw ParseError('unknown filter ":$name"');
  }

  return res;
}

bool _filterExists(String name, [String str, Map options]) =>
    _filters[name] is Function || _transformers[name] != null;
