library jaded;

import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:mirrors";
import "dart:convert" as CONV;

import "package:character_parser/character_parser.dart";
import "./runtime.dart" as jade;
import "package:markdown/markdown.dart";
import "package:sass/sass.dart" as sass;
import "package:node_shims/node_shims.dart";

part "src/utils.dart";
part "src/inline_tags.dart";
part "src/transformers.dart";
part "src/filters.dart";
part "src/filters_clients.dart";
part "src/doctypes.dart";
part "src/self_closing.dart";

part "src/nodes.dart";
part "src/lexer.dart";
part "src/parser.dart";
part "src/compiler.dart";

Map<String, RenderAsync> renderCache = Map<String, RenderAsync>();
Map<String, String> fileCache = Map<String, String>();

log(o) {
  print(o);
  return o;
}

typedef RenderAsync = Future<String> Function([Map locals]);

String parse(String str,
    {Map locals,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false,
    bool autoSemicolons = true}) {
  if (locals == null) locals = {};

  // Parse
  var parser =
      Parser(str, filename: filename, basedir: basedir, colons: colons);

  // Compile
  var compiler = _Compiler(parser.parse(),
      filename: filename,
      compileDebug: compileDebug,
      pretty: pretty,
      doctype: doctype,
      autoSemicolons: autoSemicolons)
    ..addVarReference = parser.lexer.addVarReference;

  var js = compiler.compile();

  // Debug compiler
  if (debug) {
    print('\nCompiled Function:\n\n\033[90m%s\033[0m');
    print(str);
    print(js.replaceAll(RegExp("^", multiLine: true), '  '));
  }

  //DB: Undeclared references are placeholders
  var sb = StringBuffer();
  var globalRefs = {...locals.keys, ...parser.undeclaredVarReferences()};
  for (var key in globalRefs) {
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

stripBOM(String str) => 0xFEFF == str.codeUnitAt(0) ? str.substring(1) : str;

RenderAsync compile(str,
    {Map locals,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false,
    bool autoSemicolons = true}) {
  var fn = compileBody(str,
      locals: locals,
      filename: filename,
      basedir: basedir,
      doctype: doctype,
      pretty: pretty,
      compileDebug: compileDebug,
      debug: debug,
      colons: colons,
      autoSemicolons: autoSemicolons);

  return runCompiledDartInIsolate(fn);
}

String compileBody(String str,
    {Map locals,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false,
    bool autoSemicolons = true}) {
  str = stripBOM(str.toString());

  var fnBody = parse(str,
      locals: locals,
      filename: filename,
      basedir: basedir,
      doctype: doctype,
      pretty: pretty,
      compileDebug: compileDebug,
      debug: debug,
      colons: colons,
      autoSemicolons: autoSemicolons);

  if (!compileDebug) return fnBody;

  return """
jade.debug = [Debug(lineno: 1, filename: ${filename != null ? CONV.json.encode(filename) : "null"})];
try {
$fnBody
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
}
""";
}

RenderAsync runCompiledDartInIsolate(String fn) {
//Execute fn within Isolate. Shim Jade objects.
  var isolateWrapper = """
import 'dart:isolate';
import 'package:jaded/runtime.dart';
import 'package:jaded/runtime.dart' as jade;
import 'dart:convert';

render(Map locals) {
  try{
    $fn
  } catch(e){
    print(e);
  }
}

main(List args, SendPort replyTo) {
  var html = render(json.decode(args.first));
    replyTo.send(html.toString());
}
""";

  //Hack: Write compiled dart out to a static file
  var absolutePath = "${Directory.current.path}/jaded.views.dart";
  File(absolutePath).writeAsStringSync(isolateWrapper);

  //Re-read back generated file inside an isolate
  RenderAsync renderAsync = ([Map locals = const {}]) {
    ReceivePort rPort = ReceivePort();
    var isolate = Isolate.spawnUri(
        Uri.file(absolutePath), [CONV.json.encode(locals)], rPort.sendPort);

    var completer = Completer<String>();

    isolate.catchError((_) {
      //print("isolate error: ${err}");
      completer.completeError;
    });

    //Call generated code to get the results of render()
    rPort.first.then((html) {
      completer.complete(html);
    }, onError: (_) {
      completer.completeError;
    });

    return completer.future;
  };

  return renderAsync;
}

Future<String> render(str,
    {Map locals,
    bool cache = false,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false}) {
  var completer = Completer<String>();

  // cache requires .filename
  if (cache && filename == null) {
    completer.completeError(
        ParseError('the "filename" option is required for caching'));
  } else {
    RenderAsync compileFn() => compile(str,
        locals: locals,
        filename: filename,
        basedir: basedir,
        doctype: doctype,
        pretty: pretty,
        compileDebug: compileDebug,
        debug: debug,
        colons: colons);

    if (cache) {
      RenderAsync cachedTmpl = renderCache[filename];
      if (cachedTmpl != null) {
        cachedTmpl(locals).then((html) {
          completer.complete(html);
        });
      } else {
        RenderAsync renderAsync = compileFn();
        renderAsync(locals).then((html) {
          renderCache[filename] = renderAsync;
          completer.complete(html);
        }).catchError(completer.completeError);
      }
    } else {
      //One shot
      var renderAsync = compileFn();
      renderAsync(locals).then((html) {
        completer.complete(html);
        renderAsync(
            {"__shutdown": true}); //When not caching, close port after use.
      }).catchError(completer.completeError);
    }
  }

  return completer.future;
}

Future<String> renderFile(String path,
    {Map locals,
    bool cache = false,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false}) {
  var key = path + ':string';

  try {
    var str = cache
        ? fileCache[key] != null
            ? fileCache[key]
            : (fileCache[key] = File(path).readAsStringSync())
        : File(path).readAsStringSync();

    return render(str,
        locals: locals,
        cache: cache,
        filename: filename,
        basedir: basedir,
        doctype: doctype,
        pretty: pretty,
        compileDebug: compileDebug,
        debug: debug,
        colons: colons);
  } catch (err) {
    return (Completer<String>()..completeError(err)).future;
  }
}

String renderFiles(String basedir, Iterable<dynamic> files,
    {templatesMapName = "JADE_TEMPLATES"}) {
  if (!_isVarExpr(templatesMapName))
    throw ArgumentError("'$templatesMapName' is not a valid variable name");

  var libName = basedir == "."
      ? Directory.current.path.split(Platform.pathSeparator).last
      : basedir.split(Platform.pathSeparator).last;

  if (libName.length == 0) libName = "templates";

  libName = libName.replaceAll(RegExp(r"[^a-zA-Z0-9_\$]"), "_");

  var sb = StringBuffer()
    ..writeln("library jade_$libName;")
    ..writeln("import 'package:jaded/runtime.dart';")
    ..writeln("import 'package:jaded/runtime.dart' as jade;")
    ..writeln("Map<String,Function> $templatesMapName = {");
  files.forEach((dynamic x) {
    var str = x.readAsStringSync();
    var fnBody = compileBody(str, filename: x.path, basedir: basedir);
    var pathWebStyle = x.path.replaceAll('\\', '/');
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

String renderDirectory(String basedir,
    {templatesMapName = "JADE_TEMPLATES",
    ext = ".jade",
    recursive = true,
    followLinks = false}) {
  var files = Directory(basedir)
      .listSync(recursive: recursive, followLinks: followLinks)
      .where((FileSystemEntity x) => x is File && x.path.endsWith(ext));

  return renderFiles(basedir, files, templatesMapName: templatesMapName);
}
