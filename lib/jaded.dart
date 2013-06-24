library jaded;

import "dart:io";
import "dart:json" as JSON;
import "dart:math" as Math;
import "dart:mirrors";
import "dart:isolate";
import "dart:async";
import "package:character_parser/character_parser.dart";

part "utils.dart";
part "inline_tags.dart";
part "transformers.dart";
part "filters.dart";
part "filters_clients.dart";
part "doctypes.dart";
part "self_closing.dart";

part "nodes.dart";
part "lexer.dart";
part "parser.dart";
part "compiler.dart";

Map cache = {};

log(o){
  print(o);
  return o;
}

parse(String str, [Map options])
{
  if (options == null) options = {};
  
  var filename = options['filename']; 
  var pretty = _or(options['pretty'], () => false);
  var compileDebug = _or(options['compileDebug'], () => false);
  var debug = _or(options['debug'], () => false);
  var doctype = options['doctype'];
  var self = _or(options['self'], () => true);
  var client = _or(options['client'], () => false);
    
  // Parse
  var parser = new Parser(str, filename, options);
//  try {

    // Compile
    var compiler = new Compiler(parser.parse(), 
        filename:filename,
        compileDebug:compileDebug,
        pretty:pretty,
        doctype:doctype);
    
    var js = compiler.compile();

    // Debug compiler
    if (debug) {
      print('\nCompiled Function:\n\n\033[90m%s\033[0m');
      print(js.replaceAll(new RegExp("^",multiLine:true), '  '));
    }

    return ''
      + 'var buf = [];\n'
      + (self
        ? 'var self = locals; if (self == null) self = {};\n' + js
        : addWith('locals || {}', js, ['jade', 'buf'])) + ';'
      + 'return buf.join("");';
//  } catch (err) {
//    parser = parser.context();
//    jade.rethrows(err, parser.filename, parser.lexer.lineno);
//  }
}

stripBOM(String str) =>
  0xFEFF == str.codeUnitAt(0)
    ? str.substring(1)
    : str;

Future<String> compile(str, [Map options]){
  if (options == null) options = {};
  var filename = options['filename'] != null
      ? JSON.stringify(options['filename'])
      : 'undefined';
  var fn;

  str = stripBOM(str.toString());

  if (options['compileDebug'] != false) {
    fn = [
          'jade.debug = [{ "lineno": 1, "filename": "$filename" }];'
          , 'try {'
          , parse(str, options)
          , '} catch (err) {'
          , '  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);'
          , '}'
          ].join('\n');
  } else {
    fn = parse(str, options);
  }

  return runCompiledDartInIsolate(fn); 
  
//  throw new UnimplementedError(); 
//  if (options['client']) return new Function('locals', fn)
//  fn = new Function('locals, jade', fn)
//  return (locals) => fn(locals, Object.create(runtime));
}

int times = 0;
Future<String> runCompiledDartInIsolate(String fn) {
  print("\n\n#${++times}:");
  print(fn);

//Execute fn within Isolate. Shim Jade objects.
  var isolateWrapper = 
"""
import 'dart:isolate';
import '../lib/runtime.dart' as runtime;

class Jade {
  List<DebugSrc> debug = [new DebugSrc()];
  Function merge = runtime.merge;
  Function nulls = runtime.nulls;
  Function joinClasses = runtime.joinClasses;
  Function attrs = runtime.attrs;
  Function escape = runtime.escape;
  Function rethrows = runtime.rethrows;
}
class DebugSrc {
  String filename;
  int lineno;
  DebugSrc([this.filename,this.lineno]);
}

render(Jade jade, Map locals) { 
  $fn 
}

main() {
  port.receive((msg, SendPort replyTo) {
    var html = render(new Jade(),{});
    replyTo.send(html.toString());
  });
}
""";

  var completer = new Completer();
  
  //Ugly hack: Write compiled dart out to a static file
  new File("jaded-codegen.dart").writeAsStringSync(isolateWrapper);  
  
  //Re-read back generated file inside an isolate
  var renderPort = spawnUri("jaded-codegen.dart");
  
  //Call generated code to get the results of render()
  renderPort.call("").then((html) {
    completer.complete(html);
  });
  
  return completer.future; 
}    

render(str, [Map options, Function fn]){
  if (options == null) options = {};

  // cache requires .filename
  if (options['cache'] == true && options['filename'] == null) {
    return fn(new ParseError('the "filename" option is required for caching'));
  }

//  try {
    var path = options['filename'];
    var tmpl = options['cache'] == true
      ? cache[path] != null ? cache[path] : (cache[path] = compile(str, options))
      : compile(str, options);
    fn(null, tmpl(options));
//  } catch (err) {
//    if (fn != null) fn(err);
//    else {
//      print(err);
//      try {
//        print({'line':err.line, 'column':err.column, 'url':err.url});
//      } catch (ignore){}
//      
//      throw err;
//    }
//  }
}

renderFile(String path, [Map options, Function fn]){
  var key = path + ':string';

  if (options == null) options = {};

  try {
    options['filename'] = path;
    var str = options['cache']
      ? cache[key] != null ? cache[key] : (cache[key] = new File(path).readAsStringSync())
      : new File(path).readAsStringSync();
    render(str, options, fn);
  } catch (err) {
    fn(err);
  }
}

String addWith(a, b, list){
  throw new ParseError("Not Implemented");
  //requires: https://github.com/ForbesLindesay/with/blob/master/index.js -dep uglifyjs
}