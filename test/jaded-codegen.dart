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
  jade.debug = [{ "lineno": 1, "filename": "undefined" }];
try {
var buf = [];
var self = locals; if (self == null) self = {};
buf.add("<p></p>'foo'");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  port.receive((msg, SendPort replyTo) {
    var html = render(new Jade(),{});
    replyTo.send(html.toString());
  });
}
