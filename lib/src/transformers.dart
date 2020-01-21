part of jaded;

var _transformers = <String, _Transformer>{}
  ..['cdata'] = _CDataTransformer()
  ..['css'] = _CssTransformer()
  ..['js'] = _JsTransformer()
  ..['md'] = _MarkdownTransformer()
  ..['markdown'] = _MarkdownTransformer()
  ..['sass'] = _SassTransformer()
  ..['scss'] = _SassTransformer();

class _CDataTransformer extends _Transformer {
  String name = 'cdata';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'xml';

  dynamic sync(String str, Map options) {
    var ret = cache(options);
    return ret != null ? ret : cache(options, '<![CDATA[\n$str\n]]>');
  }
}

class _CssTransformer extends _Transformer {
  String name = 'css';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'css';

  dynamic sync(String str, Map options) {
    var ret = cache(options);
    return ret != null ? ret : cache(options, str);
  }
}

class _JsTransformer extends _Transformer {
  String name = 'js';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'js';

  dynamic sync(String str, Map options) {
    var ret = cache(options);
    return ret != null ? ret : cache(options, str);
  }
}

class _MarkdownTransformer extends _Transformer {
  String name = 'markdown';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'html';

  dynamic sync(String str, Map options) {
    var ret = cache(options);
    return ret != null ? ret : cache(options, markdownToHtml(str));
  }
}

class _SassTransformer extends _Transformer {
  String name = 'sass';
  List engines = ['.'];
  String outputFormat = 'css';

  dynamic sync(String str, Map options) {
    var ret = cache(options);
    return ret != null ? ret : cache(options, sass.compileString(str));
  }
}

abstract class _Transformer {
  String outputFormat;
  String name;
  List engines;
  bool isBinary = false;
  dynamic sync(String str, Map options);
  //ignore: prefer_final_fields
  Map _cache = {};
  dynamic cache(Map options, [String str]) {
    var key = runtimeType.toString() +
        (options != null ? conv.json.encode(options) : "");
    if (str != null) _cache[key] = str;
    return _cache[key];
  }

  dynamic clone(Map options) {
    var ret = {};
    for (var key in options.keys) {
      ret[key] = options[key];
    }
    return ret;
  }

  void loadModule() {}

  String fixString(String str) {
    if (str == null) return str;
    //convert buffer to string
    str = str.toString();
    // Strip UTF-8 BOM if it exists
    str = (0xFEFF == str.codeUnitAt(0) ? str.substring(1) : str);
    //remove `\r` added by windows
    return str.replaceAll(RegExp(r"\r"), '');
  }

  dynamic minify(String str, Map options) => str;

  dynamic renderSync(String str, Map options) {
    if (options == null) options = {};
    options = clone(options);
    loadModule();
//    if (_renderSync) {
    return minify(sync((isBinary ? str : fixString(str)), options), options);
//    } else if (sudoSync) {
//      options.sudoSync = true;
//      var res, err;
//      _renderAdynamic sync((isBinary 
//          ? str 
//          : fixString(str)), options, function (e, val) {
//        if (e) err = e;
//        else res = val;
//      });
//      if (err) throw err;
//      else if (res != undefined) return minify(res, options);
//      else if (typeof sudoSync === 'string') throw new Error(sudoSync.replace(/FILENAME/g, options.filename || ''));
//      else throw new Error('There was a problem transforming '
//        + (options.filename || '') + ' syncronously using ' + name);
//    } else {
//      throw new Error(name + ' does not support transforming syncronously.');
//    }
  }
}
