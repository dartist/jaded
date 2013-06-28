import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: "cases/filters.cdata.jade")];
try {
var filename = locals['filename'];
var pretty = locals['pretty'];
var basedir = locals['basedir'];
var buf = [];
var self = locals; if (self == null) self = {};
jade.indent = [];
var val, users;
users = ([{ 'name': 'tobi', 'age': 2 }]);
buf.add("\n<fb:users>");
// iterate users
;((){
  var $$obj = users;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var user = $$obj[$index];

buf.add("\n  <fb:user" + (jade.attrs({ 'age':(user['age']) }, {"age":true})) + ">" + (jade.escape((jade.interp = user["name"]) == null ? '' : jade.interp)) + "\n  </fb:user>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var user = $$obj[$index];

buf.add("\n  <fb:user" + (jade.attrs({ 'age':(user['age']) }, {"age":true})) + ">" + (jade.escape((jade.interp = user[&#39;name&#39;]) == null ? '' : jade.interp)) + "\n  </fb:user>");
    }

  }
})();

buf.add("\n</fb:users>");;return buf.join("");
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
