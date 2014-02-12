part of jaded;

abstract class Node {
  bool yield = false;
  bool textOnly = false;
  Block block;
  bool debug;
  bool isText = false;
  String filename;
  bool buffer = false; //?
  int line; //?
  get isInline => false;
  get isBlock => false;

  Node clone() => this;

  get label => "$runtimeType: ${block != null ? block.nodes.length: 0} blocks";
  toString() => toDebugString(0);

  toDebugString(int indent) {
    var spaces = new List.filled(indent, '').join("  ");
    var str = "$spaces$label";
    if (block != null){
      str += block.toDebugString(indent + 1);
    }

    return str;
  }
}


class Block extends Node {
  List<Node> nodes = [];
  bool isBlock = true;
  String mode;
  List prepended = [];
  List appended = [];
  Parser parser;

  Block([node]){
    if (node != null)
      nodes.add(node);
  }

  void replace(Block other){
    other.nodes = nodes;
  }

  add(Node node){
    nodes.add(node);
  }

  get isEmpty => nodes.isEmpty;

  unshift(Node node) {
    nodes.insert(0, node);
    return nodes.length;
  }

  includeBlock(){
    var ret = this;

    for (var node in nodes){
      if (node.yield) return node;
      else if (node.textOnly) continue;
      else if (node is Block) ret = node.includeBlock();
      else if (node.block != null && !node.block.isEmpty) ret = node.block.includeBlock();
      if (ret.yield) return ret;
    }

    return ret;
  }

  clone(){
    var clone = new Block();
    for (var node in nodes){
      clone.push(node.clone());
    }
    return clone;
  }

  get label => "$runtimeType: ${nodes.length} nodes:";
  toString() => toDebugString(0);

  toDebugString(int indent) {
    var spaces = new List.filled(indent, '').join("  ");
    var str = "$spaces$label";
    for (var i=0; i<nodes.length; i++){
      var node = nodes[i];
      str += "\n$spaces  [$i] ${node.toDebugString(indent+1)}";
    }
    return str;

  }
}


class Attr {
  String name;
  var val;
  bool escaped;

  Attr([this.name,this.val,this.escaped]);

  toString() => "$name = $val / $escaped";
}

class Attrs extends Node {
  List<Attr> attrs = [];

  void setAttribute(String name, var val, [bool escaped=false]){
    attrs.add(new Attr(name, val, escaped));
  }

  void removeAttribute(String name){
    for (var i = 0, len = attrs.length; i < len; ++i) {
      if (attrs[i] != null && attrs[i].name == name)
        this.attrs.removeAt(i);
    }
  }

  getAttribute(name) {
    var attr = attrs.firstWhere((x) => x != null && x.name == name, orElse:() => null);
    return attr != null ? attr.val : null;
  }

}


class BlockComment extends Node {
  Block block;
  String val;
  bool buffer;

  BlockComment([this.val, this.block, this.buffer]);
}


class Case extends Node {
  String expr;
  Block block;

  Case([this.expr, this.block]);
}

class When extends Node {
  String expr;
  Block block;
  bool debug = false;

  When([this.expr, this.block]);
}


class Code extends Node {
  String val;
  bool buffer;
  bool escape;
  bool debug;

  Code([this.val, this.buffer, this.escape]){
    if (new RegExp(r"^ *else").hasMatch(val))
      debug = false;
    if (buffer == null)
      buffer = false;
  }

  toString() => val;
}


class Comment extends Node {
  String val;

  Comment([this.val, buffer]){
    this.buffer = buffer;
  }
}


class Doctype extends Node {
  String val;
  Doctype(this.val);
}


class Each extends Node {
  dynamic obj;
  String val;
  String key;
  Block block;
  Node alternative;

  Each(this.obj, this.val, this.key, [this.block]);
}


class Filter extends Node {
  String name;
  Block block;
  Map attrs;

  Filter(this.name, this.block, this.attrs);
}


class Literal extends Node {
  String str;
  Literal(this.str);
}


class Mixin extends Tag {
  String name;
  String args;
  Block block;
  bool call = false;
  List attrs = [];

  Mixin([this.name, this.args, this.block, this.call]);
}


class Tag extends Attrs {
  String name;
  Block block;
  List attrs = [];
  bool selfClosing = false;
  Code code;

  Tag([this.name, this.block]){
    if (block == null)
      block = new Block();
  }

  clone(){
    return new Tag(this.name, this.block.clone())
      ..line = line
      ..attrs = attrs
      ..textOnly = textOnly;
  }

  get isInline => inlineTags.contains(this.name);

  bool canInline(){
    var nodes = block.nodes;

    isInline(Node node){
      // Recurse if the node is a block
      if (node.isBlock)
        return (node as Block).nodes.every(isInline);
      return node.isText || (node.isInline);
    }

    // Empty tag
    if (nodes.length == 0) return true;

    // Text-only or inline-only tag
    if (1 == nodes.length) return isInline(nodes[0]);

    // Multi-line inline-only tag
    if (this.block.nodes.every(isInline)) {
      for (var i = 1, len = nodes.length; i < len; ++i) {
        if (nodes[i-1].isText && nodes[i].isText)
          return false;
      }
      return true;
    }

    // Mixed tag
    return false;
  }

  get label => "$runtimeType: <$name${selfClosing ? '/' : '></$name>'}";
}


class Text extends Node {
  String val = '';
  bool isText = true;

  Text(line){
    if (line is String)
      this.val = line;
  }

  toString() => val;
}
