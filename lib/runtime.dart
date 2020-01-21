library runtime;

///ignore_for_file:public_member_api_docs,type_annotate_public_apis,omit_local_variable_types,lines_longer_than_80_chars,prefer_interpolation_to_compose_strings
import 'dart:convert' as conv;
import 'dart:io';
import 'dart:math' as math;

var interp;
List<Debug> debug;
List indent;

class Debug {
  String filename;
  int lineno;
  Debug({this.lineno, this.filename});
}

bool nulls(val) => val != null && val != '';

dynamic joinClasses(val) =>
    val is List ? val.map(joinClasses).where(nulls).join(' ') : val;

Map merge(Map a, Map b, [escaped]) {
  var ac = a['class'];
  var bc = b['class'];

  if (ac is! List<dynamic>) {
    if (ac is Iterable) {
      ac = <dynamic>[...ac];
    } else {
      ac = <dynamic>[]..add(ac);
    }
  }
  if (bc is! List<dynamic>) {
    if (bc is Iterable) {
      bc = <dynamic>[...bc];
    } else {
      bc = <dynamic>[]..add(bc);
    }
  }
  a['class'] = ([...ac, ...bc]).where(nulls).toList();
  for (var key in b.keys) {
    if (key != 'class') {
      a[key] = b[key];
    }
  }

  return a;
}

String attrs(Map obj, [Map escaped]) {
  var buf = [];
  bool terse = obj['terse'];

  obj.remove('terse');
  List<dynamic> keys = obj.keys.toList();
  int len = keys.length;

  if (len > 0) {
    buf.add('');
    for (var i = 0; i < len; ++i) {
      String key = keys[i];
      var val = obj[key];

      if (val is bool || null == val) {
        if (val != null && val) {
          if (terse != null && terse) {
            buf.add(key);
          } else {
            buf.add('$key="$key"');
          }
        }
      } else if (0 == key.indexOf('data') && val is! String) {
        buf.add("$key='${conv.json.encode(val)}'");
      } else if ('class' == key) {
        if ((val = escape(joinClasses(val))) != null) {
          if (val != '') buf.add('$key="$val"');
        }
      } else if (escaped != null &&
          escaped[key] != null &&
          escaped[key] != false) {
        buf.add('$key="${escape(val)}"');
      } else {
        buf.add('$key="$val"');
      }
    }
  }

  return buf.join(' ');
}

String escape(html) => '$html'
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

class RuntimeError extends Error {
  String path;
  String message;
  Error err;
  @override
  String toString() => '$message $path';
}

void rethrows(err, filename, lineno) {
  print('filename: $filename, lineno: $lineno, err: $err');
  if (filename == null || filename == 'undefined') {
    throw err;
  }
//  if (typeof window != 'undefined') throw err;

  dynamic context = 3;
  String str = File(filename).readAsStringSync();
  List<String> lines = str.split('\n');
  int start = math.max(lineno - context, 0);
  int end = math.min(lines.length, lineno + context);

  // Error context
  int i = 0;
  context = lines.sublist(start, end).map((line) {
    var curr = i++ + start + 1;
    return (curr == lineno ? '  > ' : '    ') + '$curr' + '| ' + line;
  }).join('\n');

  var msg = err is NoSuchMethodError
      ? err.toString()
      : 'line: ${err.line}, column ${err.column}: $err';

  // Alter exception message
  throw RuntimeError()
    ..err = err
    ..path = filename
    ..message = '${(filename ?? 'Jade')}:$lineno\n$context\n\n$msg';
}
