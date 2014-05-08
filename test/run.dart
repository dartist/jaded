import "package:unittest/unittest.dart";
import "dart:io";
import "dart:convert" as CONV;
import "package:jaded/jaded.dart";
import "package:jaded/jaded.dart" as jade;

main(){
  var missingFilters = [
    'filters.coffeescript.jade',
    'filters.less.jade',
    'filters.stylus.jade',
    'include-filter-stylus.jade',
  ];

  var cases = new Directory('cases').listSync()
    .map((FileSystemEntity fse) => fse.path)
    .where((file) => file.contains('.jade')
      && !missingFilters.any((x) => file.endsWith(x)))
    .map((file) => file.replaceAll('.jade', ''));

  print("cases: ${cases.length}");

  group("test cases", (){
    cases
//      .where((String file) => file.endsWith("include-filter"))
      .forEach((String file){
        print("testing $file...");

      var name = file.replaceAll(new RegExp(r"[-.]"), ' ');

      test(name, (){
        var path = '$file.jade';
        var str = new File(path).readAsStringSync();
        var html = new File('$file.html').readAsStringSync()
          .trim().replaceAll(new RegExp(r"\r"), '');
        RenderAsync fn = jade.compile(str, filename: path, pretty:true, basedir:'cases');

        fn({ 'title': 'Jade' }).then(expectAsync1((actual){

          if (new RegExp('filter').hasMatch(name)) {
            actual = actual.replaceAll(new RegExp(r'\n'), '');
            html = html.replaceAll(new RegExp(r'\n'), '');
          }

          expect(CONV.JSON.encode(actual.trim()), equals(CONV.JSON.encode(html)));
        }));
      });
    });

  });

}