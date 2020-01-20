import "package:test/test.dart";
import "dart:io";
import "dart:convert" as CONV;
import "package:jaded/jaded.dart";
import "package:jaded/jaded.dart" as jade;

main() {
  var missingFilters = [
    'filters.coffeescript.jade',
    'filters.less.jade',
    'filters.stylus.jade',
    'include-filter-stylus.jade',
  ];

  var cases = Directory('cases')
      .listSync()
      .map((FileSystemEntity fse) => fse.path)
      .where((file) =>
          file.contains('.jade') &&
          !missingFilters.any((x) => file.endsWith(x)))
      .map((file) => file.replaceAll('.jade', ''));

  print("cases: ${cases.length}");

  group("test cases", () {
    cases
//      .where((String file) => file.endsWith("include-filter"))
        .forEach((String file) {
      print("testing $file...");

      var name = file.replaceAll(RegExp(r"[-.]"), ' ');

      test(name, () {
        var path = '$file.jade';
        var str = File(path).readAsStringSync();
        var html = File('$file.html')
            .readAsStringSync()
            .trim()
            .replaceAll(RegExp(r"\r"), '');
        RenderAsync fn =
            jade.compile(str, filename: path, pretty: true, basedir: 'cases');

        fn({'title': 'Jade'}).then(expectAsync1((actual) {
          if (RegExp('filter').hasMatch(name)) {
            actual = actual.replaceAll(RegExp(r'\n'), '');
            html = html.replaceAll(RegExp(r'\n'), '');
          }

          expect(
              CONV.json.encode(actual.trim()), equals(CONV.json.encode(html)));
        }));
      });
    });
  });
}
