part of jaded;

var transformers = new Map<String,Transformer>();

abstract class Transformer {
  String outputFormat;
  renderSync(String str, Map options);
}