library jaded;

import "dart:io";
import "dart:json" as JSON;
import "dart:math" as Math;
import "dart:mirrors";
import "dart:isolate";
import "dart:async";
import "package:character_parser/character_parser.dart";
import "runtime.dart" as jade;

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

Map<String,RenderAsync> cache = new Map<String,RenderAsync>();
Map<String,String> fileCache = new Map<String,String>();


log(o){
  print(o);
  return o;
}

typedef Future<String> RenderAsync([Map locals]);

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
    
    var sb = new StringBuffer();
    for (var key in options.keys){
      sb.write("var $key = locals['$key'];\n");
    }
    
    return '${sb.toString()}'
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

int times = 0;
RenderAsync compile(str, [Map options]){
  if (options == null) options = {};
  var filename = options['filename'] != null
      ? JSON.stringify(options['filename'])
      : 'null';
  var fn;

  str = stripBOM(str.toString());

  if (options['compileDebug'] != false) {
    fn = [
          'jade.debug = [new Debug(lineno: 1, filename: $filename)];'
          , 'try {'
          , parse(str, options)
          , '} catch (err) {'
          , '  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);'
          , '}'
          ].join('\n');
  } else {
    fn = parse(str, options);
  }
//  print("\n\n#${++times}:");
//  print(fn);

  return runCompiledDartInIsolate(fn); 
}

RenderAsync runCompiledDartInIsolate(String fn) {

//Execute fn within Isolate. Shim Jade objects.
  var isolateWrapper = 
"""
import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  $fn 
}

main() {
  port.receive((Map msg, SendPort replyTo) {
    if (msg["__shutdown"] == true) {
      port.close();
      return;
    }
    var html = render(msg);
    replyTo.send(html.toString());
  });
}
""";

  //Ugly hack: Write compiled dart out to a static file
  new File("jaded-codegen.dart").writeAsStringSync(isolateWrapper);  
  
  //Re-read back generated file inside an isolate
  SendPort renderPort = spawnUri("jaded-codegen.dart");
  
  RenderAsync renderAsync = ([Map locals]){
    if (locals == null)
      locals = {};

    var completer = new Completer();
    
    //Call generated code to get the results of render()
    renderPort.call(locals).then((html) {
      completer.complete(html);
    })
    .catchError(completer.completeError);
    
    return completer.future;    
  };
  
  return renderAsync;
}    

Future<String> render(str, [Map options]){
  if (options == null) options = {};

  var completer = new Completer();

  // cache requires .filename
  if (options['cache'] == true && options['filename'] == null) {
    completer.completeError(new ParseError('the "filename" option is required for caching'));
  }
  else
  {
//  try {
    
    var path = options['filename'];    
    if (options['cache'] == true){
      RenderAsync cachedTmpl = cache[path]; 
      if (cachedTmpl != null){
        cachedTmpl(options).then((html){
          completer.complete(html);
        });
      }
      else {
        RenderAsync renderAsync = compile(str, options);
        renderAsync(options).then((html){
          cache[path] = renderAsync;
          completer.complete(html);
        }).catchError(completer.completeError);
      }
    }
    else {
      //One shot
      var renderAsync = compile(str, options);
      renderAsync(options).then((html){
        completer.complete(html);        
        renderAsync({ "__shutdown": true }); //When not caching, close port after use.
      }).catchError(completer.completeError);
    }
    
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
  
  return completer.future;
}

Future<String> renderFile(String path, [Map options]){
  var key = path + ':string';

  if (options == null) options = {};

  try {
    options['filename'] = path;
    options['cache'] = true;

    var str = options['cache']
      ? fileCache[key] != null ? fileCache[key] : (fileCache[key] = new File(path).readAsStringSync())
      : new File(path).readAsStringSync();

    return render(str, options);
    
  } catch (err) {
    return (new Completer()..completeError(err)).future;
  }
}

String addWith(a, b, list){
  throw new ParseError("Not Implemented");
  //requires: https://github.com/ForbesLindesay/with/blob/master/index.js -dep uglifyjs
}