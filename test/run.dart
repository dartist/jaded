import "package:unittest/unittest.dart";
import "dart:io";
import "dart:json" as JSON;
import "../lib/jaded.dart";
import "../lib/jaded.dart" as jade;


// test cases
renderEquals(String expected, String jade, [Map options, String reason]){
  if (options == null)
    options = {};
//    options['debug'] = true;
  RenderAsync fn = compile(jade, options);
  return fn(options).then(expectAsync1((html){
    fn({"__shutdown":true}); //close isolate after use
    expect(html, equals(expected), reason:reason);
  }));
}

main(){
  var missingFilters = [
    'filters.coffeescript.jade',
    'filters.less.jade',
    'filters.markdown.jade',
    'filters.stylus.jade',
    'include-filter-stylus.jade',
    'include-filter.jade', //markdown
    'include-only-text.jade',
    'inheritance.extend.mixins.jade',
  ];
  
  var cases = new Directory('cases').listSync()
    .map((FileSystemEntity fse) => fse.path)
    .where((file) => file.contains('.jade') 
      && !missingFilters.any((x) => file.endsWith(x)))
    .map((file) => file.replaceAll('.jade', ''));

  print("cases: ${cases.length}");
  
  group("test cases", (){
    cases
//      .skip(32)
//      .take(1)
      .forEach((String file){
        print("testing $file...");
        
      var name = file.replaceAll(new RegExp(r"[-.]"), ' ');
           
      test(name, (){
        var path = '$file.jade';
        var str = new File(path).readAsStringSync();
        var html = new File('$file.html').readAsStringSync()
          .trim().replaceAll(new RegExp(r"\r"), '');
        RenderAsync fn = jade.compile(str, { 'filename': path, 'pretty': true, 'basedir': 'cases' });
        
        fn({ 'title': 'Jade' }).then(expectAsync1((actual){
          
          if (new RegExp('filter').hasMatch(name)) {
            actual = actual.replaceAll(new RegExp(r'\n'), '');
            html = html.replaceAll(new RegExp(r'\n'), '');
          }

          expect(JSON.stringify(actual.trim()), equals(JSON.stringify(html)));
        }));
      });
    });

  });


}