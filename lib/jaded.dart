library jaded;

import "dart:io";
import "dart:json" as JSON;
import "dart:math" as Math;
import "dart:mirrors";
import "dart:isolate";
import "dart:async";
import "package:character_parser/character_parser.dart";
import "package:jaded/runtime.dart" as jade;
import "package:node_shims/path.dart";
import "package:node_shims/js.dart";
import "package:markdown/markdown.dart";

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

Map<String,RenderAsync> renderCache = new Map<String,RenderAsync>();
Map<String,String> fileCache = new Map<String,String>();


log(o){
  print(o);
  return o;
}

typedef Future<String> RenderAsync([Map locals]);

String parse(String str, {
  Map locals,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false,
  bool autoSemicolons:true
  })
{
  if (locals == null) locals = {};
  
  // Parse
  var parser = new Parser(str, filename:filename, basedir:basedir, colons:colons);

  // Compile
  var compiler = new Compiler(parser.parse(), 
      filename:filename,
      compileDebug:compileDebug,
      pretty:pretty,
      doctype:doctype,
      autoSemicolons:autoSemicolons)
    ..addVarReference = parser.lexer.addVarReference;
  
  var js = compiler.compile();

  // Debug compiler
  if (debug) {
    print('\nCompiled Function:\n\n\033[90m%s\033[0m');
    print(str);
    print(js.replaceAll(new RegExp("^",multiLine:true), '  '));
  }
  
  //DB: Undeclared references are placeholders
  var sb = new StringBuffer();
  var globalRefs = locals.keys.toSet()
      ..addAll(parser.undeclaredVarReferences());
  for (var key in globalRefs){
    sb.write("var $key = locals['$key'];\n");
  }
  
  //DB: write any var declarations at the top
  if (!parser.varDeclarations.isEmpty)
    sb.write("var ${(parser.varDeclarations).join(', ')};\n");
    
  return """
$sb
var buf = [];
var self = locals; 
if (self == null) self = {};
$js;
return buf.join("");
""";

}

stripBOM(String str) =>
  0xFEFF == str.codeUnitAt(0)
    ? str.substring(1)
    : str;

RenderAsync compile(str, {
  Map locals,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false,
  bool autoSemicolons:true
  }){

  var fn = compileBody(str,       
      locals:locals, 
      filename:filename, 
      basedir:basedir,
      doctype:doctype,
      pretty:pretty,
      compileDebug:compileDebug,
      debug:debug,
      colons:colons,
      autoSemicolons:autoSemicolons);
  
  return runCompiledDartInIsolate(fn); 
}

String compileBody(str, {
  Map locals,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false,
  bool autoSemicolons:true
  }){

  str = stripBOM(str.toString());

  var fn;
  var fnBody = parse(str,
      locals:locals, 
      filename:filename, 
      basedir:basedir,
      doctype:doctype,
      pretty:pretty,
      compileDebug:compileDebug,
      debug:debug,
      colons:colons,
      autoSemicolons:autoSemicolons);
  
  if (!compileDebug) 
    return fnBody;
  
  return """
jade.debug = [new Debug(lineno: 1, filename: ${filename != null ? JSON.stringify(filename) : "null"})];
try {
$fnBody
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
}
""";

}

RenderAsync runCompiledDartInIsolate(String fn) {

//Execute fn within Isolate. Shim Jade objects.
  var isolateWrapper = 
"""
import 'dart:isolate';
import 'package:jaded/runtime.dart';
import 'package:jaded/runtime.dart' as jade;

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
  new File("jaded.views.dart").writeAsStringSync(isolateWrapper);  
  
  //Re-read back generated file inside an isolate
  SendPort renderPort = spawnUri("jaded.views.dart");
  
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

Future<String> render(str, {
  Map locals,
  bool cache:false,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false
  }){

  var completer = new Completer();

  // cache requires .filename
  if (cache && filename == null) {
    completer.completeError(new ParseError('the "filename" option is required for caching'));
  }
  else
  {
    RenderAsync compileFn() =>
      compile(str,
        locals:locals, 
        filename:filename, 
        basedir:basedir,
        doctype:doctype,
        pretty:pretty,
        compileDebug:compileDebug,
        debug:debug,
        colons:colons);
    
    if (cache){
      RenderAsync cachedTmpl = renderCache[filename]; 
      if (cachedTmpl != null){
        cachedTmpl(locals).then((html){
          completer.complete(html);
        });
      }
      else{
        RenderAsync renderAsync = compileFn();
        renderAsync(locals).then((html){
          renderCache[filename] = renderAsync;
          completer.complete(html);
        }).catchError(completer.completeError);
      }
    }
    else{
      //One shot
      var renderAsync = compileFn();
      renderAsync(locals).then((html){
        completer.complete(html);        
        renderAsync({ "__shutdown": true }); //When not caching, close port after use.
      }).catchError(completer.completeError);
    }
  }
  
  return completer.future;
}

Future<String> renderFile(String path, {
  Map locals,
  bool cache:false,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false
  })
{
  var key = path + ':string';

  try {
    var str = cache
      ? fileCache[key] != null ? fileCache[key] : (fileCache[key] = new File(path).readAsStringSync())
      : new File(path).readAsStringSync();

    return render(str, 
      locals:locals, 
      cache:cache,
      filename:filename, 
      basedir:basedir,
      doctype:doctype,
      pretty:pretty,
      compileDebug:compileDebug,
      debug:debug,
      colons:colons);
    
  } catch (err) {
    return (new Completer()..completeError(err)).future;
  }
}

String renderFiles(String basedir, Iterable<File> files, {templatesMapName:"JADE_TEMPLATES"}){
  if (!_isVarExpr(templatesMapName))
    throw new ArgumentError("'$templatesMapName' is not a valid variable name");

  var libName = basedir == "."
      ? Directory.current.path.split(Platform.pathSeparator).last
      : basedir.split(Platform.pathSeparator).last;
  
  if (libName.length == 0) 
    libName = "templates";
  
  libName = libName.replaceAll(new RegExp(r"[^a-zA-Z0-9_\$]"), "_");
  
  var sb = new StringBuffer()
    ..writeln("library jade_$libName;")
    ..writeln("import 'package:jaded/runtime.dart';")
    ..writeln("import 'package:jaded/runtime.dart' as jade;")
    ..writeln("Map<String,Function> $templatesMapName = {");
  files.forEach((File x){
    var str = x.readAsStringSync();
    var fnBody = compileBody(str, filename:x.path, basedir:basedir);
    var pathWebStyle = x.path.replaceAll('\\','/'); 
    sb.write("""
'${pathWebStyle}': ([Map locals]){///jade-begin
  if (locals == null) locals = {};
  $fnBody
},///jade-end
""");    
  });
  sb.writeln("};");

  var tmpls = sb.toString();
  return tmpls;
}

String renderDirectory(String basedir, {
  templatesMapName:"JADE_TEMPLATES", 
  ext:".jade", 
  recursive:true, 
  followLinks:false}){
  var files = new Directory(basedir)
    .listSync(recursive:recursive, followLinks:followLinks)
    .where((FileSystemEntity x) => x is File && x.path.endsWith(ext));
  
  return renderFiles(basedir, files, templatesMapName:templatesMapName);
}
