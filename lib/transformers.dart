part of jaded;

var transformers = new Map<String,Transformer>()
..['cdata'] = new CDataTransformer()
..['css'] = new CssTransformer()
..['js'] = new JsTransformer()
..['md'] = new MarkdownTransformer()
..['markdown'] = new MarkdownTransformer();

class CDataTransformer extends Transformer {
  String name = 'cdata';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'xml';

  sync(String str, Map options){
    var ret = this.cache(options);
    return ret != null ? ret : this.cache(options, '<![CDATA[\n$str\n]]>');
  }
}

class CssTransformer extends Transformer {
  String name = 'css';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'css';

  sync(String str, Map options){
    var ret = this.cache(options);
    return ret != null ? ret : this.cache(options, str);
  }
}

class JsTransformer extends Transformer {
  String name = 'js';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'js';

  sync(String str, Map options){
    var ret = this.cache(options);
    return ret != null ? ret : this.cache(options, str);
  }
}

class MarkdownTransformer extends Transformer {
  String name = 'markdown';
  List engines = ['.']; // `.` means "no dependency"
  String outputFormat = 'html';

  sync(String str, Map options){
    var ret = this.cache(options);
    return ret != null ? ret : this.cache(options, markdownToHtml(str));
  }
}


abstract class Transformer {
  String outputFormat;
  String name;
  List engines;
  bool isBinary = false;
  dynamic sync(String str, Map options);

  Map _cache = {};
  cache(Map options, [String str]) {
    var key = this.runtimeType.toString() + (options != null ? CONV.JSON.encode(options) : "");
    if (str != null)
      _cache[key] = str;
    return _cache[key];
  }

  clone(Map options) {
    var ret = {};
    for (var key in options.keys){
      ret[key] = options[key];
    }
    return ret;
  }

  void loadModule(){}

  String fixString(String str) {
    if (str == null) return str;
    //convert buffer to string
    str = str.toString();
    // Strip UTF-8 BOM if it exists
    str = (0xFEFF == str.codeUnitAt(0)
        ? str.substring(1)
        : str);
    //remove `\r` added by windows
    return str.replaceAll(new RegExp(r"\r"), '');
  }

  dynamic minify(String str, Map options) => str;

  dynamic renderSync(String str, Map options){
    if (options == null)
      options = {};
    options = clone(options);
    this.loadModule();
//    if (this._renderSync) {
      return minify(sync((isBinary ? str : fixString(str)), options), options);
//    } else if (this.sudoSync) {
//      options.sudoSync = true;
//      var res, err;
//      this._renderAsync((this.isBinary ? str : fixString(str)), options, function (e, val) {
//        if (e) err = e;
//        else res = val;
//      });
//      if (err) throw err;
//      else if (res != undefined) return this.minify(res, options);
//      else if (typeof this.sudoSync === 'string') throw new Error(this.sudoSync.replace(/FILENAME/g, options.filename || ''));
//      else throw new Error('There was a problem transforming ' + (options.filename || '') + ' syncronously using ' + this.name);
//    } else {
//      throw new Error(this.name + ' does not support transforming syncronously.');
//    }
  }
}

