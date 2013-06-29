import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: "cases/inheritance.extend.mixins.jade")];
try {
var filename = locals['filename'];
var pretty = locals['pretty'];
var basedir = locals['basedir'];
var buf = [];
var self = locals; if (self == null) self = {};
jade.indent = [];
article_mixin(self,title){
var block = self["block"], attributes = self["attributes"], escaped = self["escaped"];
if (attributes == null) attributes = {};
if (escaped == null) escaped = {};
if ( title)
{
buf.add("\n<h1>" + (jade.escape(null == (jade.interp = title) ? "" : jade.interp)) + "</h1>");
}
jade.indent.add('');
if (block != null) block();
jade.indent.removeLast();
};
var val;
buf.add("\n<html>\n  <head>\n    <title>My Application</title>\n  </head>\n  <body>");
jade.indent.add('    ');
article_mixin({
"block": (){
buf.add("\n<p>Foo bar baz!</p>");
}
}, "The meaning of life");
jade.indent.removeLast();
buf.add("\n  </body>\n</html>");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  render({});
}
