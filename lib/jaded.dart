library jaded;

import 'dart:async';
import 'dart:convert' as conv;
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:character_parser/character_parser.dart';
import 'package:markdown/markdown.dart';
import 'package:node_shims/node_shims.dart';
import 'package:sass/sass.dart' as sass;

import './runtime.dart' as jade;

part 'src/utils.dart';
part 'src/inline_tags.dart';
part 'src/transformers.dart';
part 'src/filters.dart';
part 'src/filters_clients.dart';
part 'src/doctypes.dart';
part 'src/self_closing.dart';

part 'src/nodes.dart';
part 'src/lexer.dart';
part 'src/parser.dart';
part 'src/compiler.dart';

Map<String, RenderAsync> _renderCache = <String, RenderAsync>{};
Map<String, String> _fileCache = <String, String>{};

// dynamic _log(dynamic o) {
//   print(o);
//   return o;
// }

typedef RenderAsync = Future<String> Function([Map locals]);

///parse a string of Pug/Jade
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
  locals ??= {};

  // Parse
  var parser =
      _Parser(str, filename: filename, basedir: basedir, colons: colons);

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
    print(js.replaceAll(RegExp('^', multiLine: true), '  '));
  }

  //DB: Undeclared references are placeholders
  var sb = StringBuffer();
  var globalRefs = {...locals.keys, ...parser.undeclaredVarReferences()};
  for (var key in globalRefs) {
    sb.write("var $key = locals['$key'];\n");
  }

  //DB: write any var declarations at the top
  if (parser.varDeclarations.isNotEmpty) {
    sb.write('var ${(parser.varDeclarations).join(', ')};\n');
  }

  return '''
$sb
var buf = [];
var self = locals;
if (self == null) self = {};
$js;
return buf.join('');
''';
}

dynamic _stripBOM(String str) =>
    0xFEFF == str.codeUnitAt(0) ? str.substring(1) : str;

///compiles a string of Pug/Jade into a StringBuffer of dart, that is then written to a file, and run in a dart isolate
RenderAsync compile(String str,
    {Map locals,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false,
    bool autoSemicolons = true}) {
  var fn = _compileBody(str,
      locals: locals,
      filename: filename,
      basedir: basedir,
      doctype: doctype,
      pretty: pretty,
      compileDebug: compileDebug,
      debug: debug,
      colons: colons,
      autoSemicolons: autoSemicolons);

  return _runCompiledDartInIsolate(fn);
}

String _compileBody(String str,
    {Map locals,
    String filename,
    String basedir,
    String doctype,
    bool pretty = false,
    bool compileDebug = false,
    bool debug = false,
    bool colons = false,
    bool autoSemicolons = true}) {
  str = _stripBOM(str.toString());

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

  return '''
jade.debug = [Debug(lineno: 1, filename: ${filename != null ? conv.json.encode(filename) : 'null'})];
try {
$fnBody
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
}
''';
}

RenderAsync _runCompiledDartInIsolate(String fn) {
//Execute fn within Isolate. Shim Jade objects.
  var isolateWrapper = '''
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
''';

  //Hack: Write compiled dart out to a static file
  var absolutePath = '${Directory.current.path}/jaded.views.dart';
  File(absolutePath).writeAsStringSync(isolateWrapper);

  //Re-read back generated file inside an isolate
  Future<String> renderAsync([Map locals = const {}]) {
    var rPort = ReceivePort();
    var isolate = Isolate.spawnUri(
        Uri.file(absolutePath), [conv.json.encode(locals)], rPort.sendPort,
        errorsAreFatal: true);

    var completer = Completer<String>();

    isolate.catchError((_) {
      // print('isolate error: ${err}');
      completer.completeError;
    });

    //Call generated code to get the results of render()
    rPort.first.then((html) {
      completer.complete(html);
    }, onError: (_) {
      completer.completeError;
    });

    return completer.future;
  }

  ;

  return renderAsync;
}

///render a String of Pug/Jade
Future<String> render(String str,
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
        ParseError("the 'filename' option is required for caching"));
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
      var cachedTmpl = _renderCache[filename];
      if (cachedTmpl != null) {
        cachedTmpl(locals).then((html) {
          completer.complete(html);
        });
      } else {
        var renderAsync = compileFn();
        renderAsync(locals).then((html) {
          _renderCache[filename] = renderAsync;
          completer.complete(html);
        }).catchError(completer.completeError);
      }
    } else {
      //One shot
      var renderAsync = compileFn();
      renderAsync(locals).then((html) {
        completer.complete(html);
        renderAsync(
            {'__shutdown': true}); //When not caching, close port after use.
      }).catchError(completer.completeError);
    }
  }

  return completer.future;
}

///render a Pug/Jade file
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
  var key = '$path:string';

  try {
    var str = cache
        ? _fileCache[key].isNotEmpty
            ? _fileCache[key]
            : (_fileCache[key] = File(path).readAsStringSync())
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
  } on Exception catch (err) {
    return (Completer<String>()..completeError(err)).future;
  }
}

///render a specified set of Pug/Jade files into a map of dart funtions
String renderFiles(String basedir, Iterable<dynamic> files,
    {String templatesMapName = 'JADE_TEMPLATES'}) {
  if (!_isVarExpr(templatesMapName)) {
    throw ArgumentError("'$templatesMapName' is not a valid variable name");
  }
  var libName = basedir == '.'
      ? Directory.current.path.split(Platform.pathSeparator).last
      : basedir.split(Platform.pathSeparator).last;

  if (libName.isEmpty) libName = 'templates';

  libName = libName.replaceAll(RegExp(r'[^a-zA-Z0-9_\$]'), '_');

  var sb = StringBuffer()
    ..writeln('library jade_$libName;')
    ..writeln("import 'package:jaded/runtime.dart';")
    ..writeln("import 'package:jaded/runtime.dart' as jade;")
    ..writeln('Map<String,Function> $templatesMapName = {');

  void _feFunc(dynamic x) {
    var str = x.readAsStringSync();
    var fnBody = _compileBody(str, filename: x.path, basedir: basedir);
    var pathWebStyle = x.path.replaceAll('\\', '/');
    sb.write('''
'$pathWebStyle': ([Map locals]){///jade-begin
  if (locals == null) locals = {};
  $fnBody
},///jade-end
''');
  }

  files.forEach(_feFunc);

  sb.writeln('};');

  var tmpls = sb.toString();
  return tmpls;
}

///render a directory of Pug/Jade files
String renderDirectory(String basedir,
    {String templatesMapName = 'JADE_TEMPLATES',
    String ext = '.jade',
    bool recursive = true,
    bool followLinks = false}) {
  var files = Directory(basedir)
      .listSync(recursive: recursive, followLinks: followLinks)
      .where((x) => x is File && x.path.endsWith(ext));

  return renderFiles(basedir, files, templatesMapName: templatesMapName);
}
