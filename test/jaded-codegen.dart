import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: null)];
try {
var buf = [];
var self = locals; if (self == null) self = {};
var val;
buf.add("<foo><bar>" + (jade.escape(null == (jade.interp = "bar") ? "" : jade.interp)) + "<baz>" + (jade.escape(null == (jade.interp = "baz") ? "" : jade.interp)) + "</baz></bar></foo>");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
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
