import "dart:io";
import "package:jaded/jaded.dart";
import "package:jaded/jaded.dart" as jade;
import "package:node_shims/path.dart";
import "files/jade.views.dart" as views;

compileFiles(String basedir){
  var tmpls = jade.renderDirectory(basedir);
  print(tmpls);

  new File(join([basedir,"jade.views.dart"])).writeAsStringSync(tmpls);
}

main(){
  compileFiles('files');
  var render = views.JADE_TEMPLATES['files/views/index.jade'];
  var html = render({'title':'ZZZ'});
  print(html);
}