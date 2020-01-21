import 'dart:isolate';
import 'package:jaded/runtime.dart';
import 'package:jaded/runtime.dart' as jade;
import 'dart:convert';

render(Map locals) {
  try {
    var request = locals['request'];
    var arg = locals['arg'];

    var buf = [];
    var self = locals;
    if (self == null) self = {};
// iterate request["args"]
    try {
      ;
      (() {
        var $$obj = request["args"];
        if ($$obj is Iterable) {
          for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
            var arg = $$obj.elementAt($index);

            buf.add("<li>" +
                (jade.escape(null == (jade.interp = arg) ? "" : jade.interp)) +
                "</li>");
          }
        } else {
          var $$l = 0;
          for (var $index in $$obj.keys) {
            $$l++;
            var arg = $$obj[$index];

            buf.add("<li>" +
                (jade.escape(null == (jade.interp = arg) ? "" : jade.interp)) +
                "</li>");
          }
        }
      })();
    } catch (e) {
      print("");
    }
    ;
    return buf.join('');
  } catch (e) {
    print(e);
  }
}

main(List args, SendPort replyTo) {
  var html = render(json.decode(args.first));
  replyTo.send(html.toString());
}
