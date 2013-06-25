import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: "undefined")];
try {
var buf = [];
var self = locals; if (self == null) self = {};
buf.add("yo, " + (jade.escape((jade.interp = name) == null ? '' : jade.interp)) + " is cool");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  port.receive((msg, SendPort replyTo) {
    var html = render({});
    replyTo.send(html.toString());
  });
}
