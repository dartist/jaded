import 'dart:io';
import 'package:jaded/jaded.dart' as jade;
import 'package:node_shims/node_shims.dart';
import 'files/jade.views.dart' as views;

void compileFiles(String basedir) {
  var tmpls = jade.renderDirectory(basedir);
  print(tmpls);

  var file = File(join([basedir, 'jade.views.dart']));

  if (!file.existsSync()) {
    file.createSync();
  }

  file.writeAsStringSync(tmpls);
}

void main() {
  compileFiles('files');
  var render = views.JADE_TEMPLATES['files/views/index.jade'];
  var html = render({'title': 'ZZZ'});
  print(html);
}
