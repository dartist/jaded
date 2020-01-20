import 'dart:io';
import 'package:jaded/jaded.dart' as jade;

main() {
  var basedir = Directory('files').path;
  var templs = jade.renderDirectory(basedir + '/views');
  var file = File(basedir + '/jade.views.dart');
  file.writeAsStringSync(templs);
}
