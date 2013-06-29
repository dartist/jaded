import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: "cases/tag.interpolation.jade")];
try {
var filename = locals['filename'];
var pretty = locals['pretty'];
var basedir = locals['basedir'];
var buf = [];
var self = locals; if (self == null) self = {};
jade.indent = [];
var val, tag, foo, item_mixin;
tag = ('p');
foo = ('bar');
buf.add("\n<" + (tag) + ">value</" + (tag) + ">\n<" + (tag) + " foo=\"bar\">value</" + (tag) + ">\n<" + (foo ? 'a' : 'li') + " something=\"something\">here</" + (foo ? 'a' : 'li') + ">");
item_mixin = (self,[icon]){
var block = self["block"], attributes = self["attributes"], escaped = self["escaped"];
if (attributes == null) attributes = {};
if (escaped == null) escaped = {};
buf.add("\n");
jade.indent.forEach((x) => buf.add(x));
buf.add("<li>");
if ( attributes.href != null)
{
buf.add("<a" + (jade.attrs(jade.merge({  }, attributes), jade.merge({}, escaped, true))) + "><img" + (jade.attrs({ 'src':(icon), "class": [('icon')] }, {"class":false,"src":true})) + "/>");
jade.indent.add('    ');
if (block != null) block();
jade.indent.removeLast();
buf.add("</a>");
}
else
{
buf.add("<span" + (jade.attrs(jade.merge({  }, attributes), jade.merge({}, escaped, true))) + "><img" + (jade.attrs({ 'src':(icon), "class": [('icon')] }, {"class":false,"src":true})) + "/>");
jade.indent.add('    ');
if (block != null) block();
jade.indent.removeLast();
buf.add("</span>");
}
buf.add("\n");
jade.indent.forEach((x) => buf.add(x));
buf.add("</li>");
};
buf.add("\n<ul>");
jade.indent.add('  ');
item_mixin({
"block": (){
buf.add("Contact");
}
}, 'contact');
jade.indent.removeLast();
jade.indent.add('  ');
item_mixin({
"block": (){
buf.add("Contact");
},
"attributes": {'href':('/contact')}, "escaped": {"href":true}
});
jade.indent.removeLast();
buf.add("\n</ul>");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  render({});
}
