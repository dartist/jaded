jaded
=====

Port of the excellent [Jade view engine](https://github.com/visionmedia/jade/) in Dart.

Now feature complete with the original jade view engine, begin by taking the comprehensive tour on
[learnjade.com](http://www.learnjade.com/) and refer to jade's 
[detailed documentation](https://github.com/visionmedia/jade#readme-contents)  
to learn about Jade's features and syntax. 

Although the aim was to have a high-fidelity port, the major syntactical difference compared with 
the original Jade (in JavaScript) is that the compiler only emits and executes Dart code, so any 
embedded code in views must be valid Dart (i.e. instead of JavaScript).

## [Installing via Pub](http://pub.dartlang.org/packages/jaded)	

Add this to your package's pubspec.yaml file:

	dependencies:
	  jaded: 0.1.9

## Public API

### Compile a Directory 

Add a pre-build step and use `renderDirectory` to statically compile all views into a single 
`jade.views.dart` file containing a Map of all compiled Jade views, e.g:

```dart
import "dart:io";
import "package:jaded/jaded.dart" as jade;

var jadeTemplates = jade.renderDirectory('.');
new File('jade.views.dart').writeAsString(jadeTemplates);
```

Writes to `jade.views.dart` snippet:

```dart
Map<String,Function> JADE_TEMPLATES = {
  './index.jade': ([Map locals]){
     ...
  },
  './dir/page.jade': ([Map locals]){
    ...
  },
}
```

Usage:

```dart
import "jade.views.dart";

var render = JADE_TEMPLATES['./index.jade'];
var html = render({'title': 'Hello Jade!'});
```

### Compile a jade view at runtime

```dart
import "package:jaded/jaded.dart" as jade;

var renderAsync = jade.compile('string of jade', { //Optional Compiler Defaults:    
  Map locals,
  String filename,
  String basedir,
  String doctype,
  bool pretty:false,
  bool compileDebug:false,
  bool debug:false,
  bool colons:false,
  bool autoSemicolons:true  
});

renderAsync(locals)
  .then((html) => print(html));
```

### Options

 - `locals`    Local variable object
 - `filename`  Used in exceptions, and required when using includes
 - `basedir`   The basedir where views start from
 - `doctype`   What doctype to use
 - `pretty`    Add pretty-indentation whitespace to output _(false by default)_
 - `debug`     Outputs tokens and function body generated
 - `compileDebug`  When `false` no debug instrumentation is compiled
 - `autoSemicolons`  Auto add missing semicolons at the end of new lines _(true by default)_
 
## Web Frameworks

 - jaded is the de-facto HTML View Engine in [Dart express web framework](https://github.com/dartist/express). 

## Current Status

All tests in 
[jade.test.dart](https://github.com/dartist/jaded/blob/master/test/jade.test.dart) 
are now passing.

All integration test cases in 
[/test/cases](https://github.com/dartist/jaded/tree/master/test/cases) 
that doesn't make use of an external DSL library are passing, specifically:  

    filters.coffeescript.jade
    filters.less.jade
    filters.stylus.jade
    include-filter-stylus.jade

When they become available support for external Web DSL's can be added to
[transformers.dart](https://github.com/dartist/jaded/blob/master/lib/transformers.dart)
in the same way as done inside Jade's feature-rich 
[transformers.js](https://github.com/ForbesLindesay/transformers/blob/master/lib/transformers.js).   

### Markdown filter

We've added the markdown filter which lets you include markdown inline:

    html
      body
        :markdown
          This is _some_ awesome **markdown**

Or as an external include:

    html
      body
        include some.md


### Pre-compilation of .jade templates 

The recommended way to execute .jade templates is to pre-compile all views with `renderDirectory()` 
out to a static file at design time. This can be automated using the 
[Dart Editor build system](http://www.dartlang.org/tools/editor/build.html) `/build.dart` file,
which can be used to trigger the background compilation of .jade views when it detects a .jade file 
was saved or deleted. 

This is the approach the [Dart Express Web Framework](https://github.com/dartist/express) takes 
with its [express_build.dart](https://github.com/dartist/express/blob/master/lib/express_build.dart) 
helper that gets triggered when a '.jade' file is touched will scan all directories for an empty 
`jade.yaml` marker and recursively pre-compiles all .jade views in that directory into a single 
`jade.views.dart` file.   

### Compile and execute at runtime - Missing eval

Jade relies on eval'ing code-gen to work which is a limitation in Dart that lacks `eval`.     
To get around this when compiling on the fly, we're currently wrapping the code-gen Dart inside 
an Isolate and writing it out to a file then immediately reading it back in with spawnUri and 
invoking the new code asynchronously in the 
[runCompiledDartInIsolate() method](https://github.com/dartist/jaded/blob/master/lib/jaded.dart#L168-L215). 

Although this works, it forces us to have an async API to convert jade to html at runtime. 
When Dart offers a sync API for evaluating Dart code we'll convert it back to a sync API.


-------

### Contributors

  - [mythz](https://github.com/mythz) (Demis Bellot)
  - [MaxHorstmann](https://github.com/MaxHorstmann) (Max Horstmann)
  
 
