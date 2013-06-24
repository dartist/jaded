jaded
=====

Port of node.js [jade view engine](https://github.com/visionmedia/jade/) for Dart.

Some tests are passing but the port is still in highly alpha experimental mode.

Some missing functionality includes delegation to 
[node.js transformers](https://github.com/ForbesLindesay/transformers) which maintains a repository
of code transformers available for different view engines in node.js.

### Missing eval

Jade relies on eval'ing code-gen to work which is a major limitation in Dart which lacks eval.     
To get around the limitation we're currently writing the code-gen Dart wrapped in an Isolate 
boilerplate out to a file then immediately reading it back in with spawnUri and invoking the 
new code asynchronously in the 
[runCompiledDartInIsolate() method](https://github.com/dartist/jaded/blob/master/lib/jaded.dart#L110-L161). 

Although this works, it forces us to have a nonideal async API to convert jade to html at runtime. 
If Dart offers a sync API for evaluating Dart code we'll convert it back to a sync API.

Another option would be to use the jade view engine as a pre-processor generating all html views at
build time we could preload in a cache avoiding compilation of jade views at runtime.


### Contributors

  - [mythz](https://github.com/mythz) (Demis Bellot)
 