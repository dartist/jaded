import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: "cases/code.iteration.jade")];
try {
var filename = locals['filename'];
var pretty = locals['pretty'];
var basedir = locals['basedir'];
var buf = [];
var self = locals; if (self == null) self = {};
jade.indent = [];
items = [1,2,3];
buf.add("\n<ul>");
items.forEach((item){
{
buf.add("\n  <li>" + (jade.escape(null == (jade.interp = item) ? "" : jade.interp)) + "</li>");
}
});
buf.add("\n</ul>");
var items = ([1,2,3]);
buf.add("\n<ul>");
// iterate items
;((){
  var $$obj = items;
  if ($$obj is Iterable) {

    for (var i = 0, $$l = $$obj.length; i < $$l; i++) {
      var item = $$obj[i];

buf.add("\n  <li" + (jade.attrs({ "class": [('item-' + ("${i}") + '')] }, {"class":true})) + ">" + (jade.escape(null == (jade.interp = item) ? "" : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var i in $$obj.keys) {
      $$l++;      var item = $$obj[i];

buf.add("\n  <li" + (jade.attrs({ "class": [('item-' + ("${i}") + '')] }, {"class":true})) + ">" + (jade.escape(null == (jade.interp = item) ? "" : jade.interp)) + "</li>");
    }

  }
})();

buf.add("\n</ul>\n<ul>");
// iterate items
;((){
  var $$obj = items;
  if ($$obj is Iterable) {

    for (var i = 0, $$l = $$obj.length; i < $$l; i++) {
      var item = $$obj[i];

buf.add("\n  <li>" + (jade.escape(null == (jade.interp = item) ? "" : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var i in $$obj.keys) {
      $$l++;      var item = $$obj[i];

buf.add("\n  <li>" + (jade.escape(null == (jade.interp = item) ? "" : jade.interp)) + "</li>");
    }

  }
})();

buf.add("\n</ul>\n<ul>");
// iterate items
;((){
  var $$obj = items;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var $item = $$obj[$index];

buf.add("\n  <li>" + (jade.escape(null == (jade.interp = $item) ? "" : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var $item = $$obj[$index];

buf.add("\n  <li>" + (jade.escape(null == (jade.interp = $item) ? "" : jade.interp)) + "</li>");
    }

  }
})();

buf.add("\n</ul>");
var nums = ([1, 2, 3]);
var letters = (['a', 'b', 'c']);
buf.add("\n<ul>");
// iterate letters
;((){
  var $$obj = letters;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var l = $$obj[$index];

// iterate nums
;((){
  var $$obj = nums;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + ": " + (jade.escape((jade.interp = l) == null ? '' : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + ": " + (jade.escape((jade.interp = l) == null ? '' : jade.interp)) + "</li>");
    }

  }
})();

    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var l = $$obj[$index];

// iterate nums
;((){
  var $$obj = nums;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + ": " + (jade.escape((jade.interp = l) == null ? '' : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + ": " + (jade.escape((jade.interp = l) == null ? '' : jade.interp)) + "</li>");
    }

  }
})();

    }

  }
})();

buf.add("\n</ul>");
var count = (1);
var counter = (() { return [count++, count++, count++]);
buf.add("}  \n<ul>");
// iterate counter()
;((){
  var $$obj = counter();
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + "</li>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var n = $$obj[$index];

buf.add("\n  <li>" + (jade.escape((jade.interp = n) == null ? '' : jade.interp)) + "</li>");
    }

  }
})();

buf.add("\n</ul>");;return buf.join("");
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
