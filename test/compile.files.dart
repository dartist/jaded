import "package:unittest/unittest.dart";
import "dart:io";
import "package:json/json.dart" as JSON;
import "package:jaded/jaded.dart";
import "package:jaded/jaded.dart" as jade;
import "package:node_shims/path.dart";
import "jaded.views.dart";

compileFiles(String basedir){
  var tmpls = jade.renderDirectory(basedir);
  print(tmpls);

  new File(join([basedir,"jade.views.dart"])).writeAsString(tmpls);
}

main(){
//  compileFiles('files');

  var render = JADE_TEMPLATES['files/views/index.jade'];
  var html = render({'title':'ZZZ'});
  print(html);
}