import 'dart:isolate';
import '../lib/runtime.dart';
import '../lib/runtime.dart' as jade;

render(Map locals) { 
  jade.debug = [new Debug(lineno: 1, filename: null)];
try {
var report = locals['report'];
var chp, sec, page;
var buf = [];
var self = locals; if (self == null) self = {};
buf.add("<div class=\"data\"><ol id=\"contents\" class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent != null))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('chapter')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
chp = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == chp && item.type == 'section'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('section')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
sec = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == chp && item.type == 'section'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('section')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
sec = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent != null))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('chapter')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
chp = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == chp && item.type == 'section'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('section')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
sec = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == chp && item.type == 'section'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('section')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
sec = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == sec && item.type == 'page'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('page')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li>");
page = item.id;
{
buf.add("<ol class=\"sortable\">");
// iterate report
;((){
  var $$obj = report;
  if ($$obj is Iterable) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj.keys) {
      $$l++;      var item = $$obj[$index];

if ( (item.parent == page && item.type == 'subpage'))
{
buf.add("<div><li" + (jade.attrs({ 'data-ref':(item.id), "class": [('subpage')] }, {"class":false,"data-ref":true})) + "><a" + (jade.attrs({ 'href':('/admin/report/detail/' + item.id) }, {"href":true})) + ">" + (jade.escape(null == (jade.interp = item.name) ? "" : jade.interp)) + "</a></li></div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol>");
}
buf.add("</div>");
}
    }

  }
})();

buf.add("</ol></div>");;return buf.join("");
} catch (err) {
  jade.rethrows(err, jade.debug[0].filename, jade.debug[0].lineno);
} 
}

main() {
  render({});
}
