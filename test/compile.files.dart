import "dart:io";
import "package:jaded/jaded.dart" as jade;
import "package:nodeify_node_shims/node_shims.dart";
import "files/jade.views.dart" as views;

compileFiles(String basedir) {
  var tmpls = jade.renderDirectory(basedir);
  print(tmpls);

  var file = File(join([basedir, "jade.views.dart"]));

  if (!file.existsSync()) {
    file.createSync();
  }
  
  file.writeAsStringSync(tmpls);
}

main() {
  compileFiles('files');
  var render = views.JADE_TEMPLATES['files/views/index.jade'];
  var html = render({'title': 'ZZZ'});
  print(html);
}
