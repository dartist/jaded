import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: null)];
try {
var buf = [];
var self = locals; if (self == null) self = {};
buf.add("<p>Users: " + (jade.escape((jade.interp = false) == null ? '' : jade.interp)) + "</p>");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  port.receive((msg, SendPort replyTo) {
    if (msg == "shutdown") {
      
    }
    var html = render({});
    replyTo.send(html.toString());
  });
}
