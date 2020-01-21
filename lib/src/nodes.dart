//ignore_for_file: non_constant_identifier_names,camel_case_types,avoid_positional_boolean_parameters,lines_longer_than_80_chars
part of jaded;

abstract class _Node {
  bool yield = false;
  dynamic textOnly = false;
  _Block block;
  bool debug;
  bool is_Text = false;
  String filename;
  String val;
  bool buffer = false; //?
  int line; //?
  bool get isInline => false;
  bool get is_Block => false;
  //ignore: avoid_returning_this
  _Node clone() => this;

  String get label => '''$runtimeType: ${block != null ? block.nodes.length : 0} blocks''';
  String toString() => toDebugString(0);

  String toDebugString(int indent) {
    var spaces = List.filled(indent, '').join("  ");
    var str = "$spaces$label";
    if (block != null) {
      str += block.toDebugString(indent + 1);
    }

    return str;
  }
}

class _Block extends _Node {
  List<_Node> nodes = [];
  bool is_Block = true;
  String mode;
  List<_Node> prepended = [];
  List<_Node> appended = [];
  _Parser parser;

  _Block([node]) {
    if (node != null) nodes.add(node);
  }

  void replace(_Block other) {
    other.nodes = nodes;
  }

  void add(_Node node) {
    nodes.add(node);
  }

  bool get isEmpty => nodes.isEmpty;

  int unshift(_Node node) {
    nodes.insert(0, node);
    return nodes.length;
  }

  dynamic include_Block() {
    var ret = this;

    for (var node in nodes) {
      if (node.yield){
        return node;}
      else if (node.textOnly){
        continue;}
      else if (node is _Block){
        ret = node.include_Block();}
      else if (node.block != null && !node.block.isEmpty){
        ret = node.block.include_Block();}
      if (ret.yield) {return ret;}
    }

    return ret;
  }

  _Block clone() {
    var clone = _Block();
    for (var node in nodes) {
      clone.add(node.clone());
    }
    return clone;
  }

  String get label => "$runtimeType: ${nodes.length} nodes:";
  String toString() => toDebugString(0);

  String toDebugString(int indent) {
    var spaces = List.filled(indent, '').join("  ");
    var str = "$spaces$label";
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      str += "\n$spaces  [$i] ${node.toDebugString(indent + 1)}";
    }
    return str;
  }
}

class _Attr {
  String name;
  dynamic val;
  bool escaped;
  //ignore: avoid_positional_boolean_parameters
  _Attr([this.name, this.val, this.escaped]);

  String toString() => "$name = $val / $escaped";
}

class _Attrs extends _Node {
  List<dynamic> attrs = [];

  void set_Attribute(String name, dynamic val, {bool escaped = false}) {
    attrs.add(_Attr(name, val, escaped));
  }

  void remove_Attribute(String name) {
    for (var i = 0, len = attrs.length; i < len; ++i) {
      if (attrs[i] != null && attrs[i].name == name) {attrs.removeAt(i);}
    }
  }

  dynamic get_Attribute(dynamic name) {
    var attr = attrs.firstWhere((x) => x != null && x.name == name,
        orElse: () => null);
    return attr != null ? attr.val : null;
  }
}

class _Block_Comment extends _Node {
  _Block block;
  String val;
  bool buffer;

  _Block_Comment([this.val, this.block, this.buffer]);
}

class _Case extends _Node {
  String expr;
  _Block block;

  _Case([this.expr, this.block]);
}

class _When extends _Node {
  String expr;
  _Block block;
  bool debug = false;

  _When([this.expr, this.block]);
}

class _Code extends _Node {
  String val;
  bool buffer;
  bool escape;
  bool debug;

  _Code([this.val, this.buffer, this.escape]) {
    if (RegExp(r"^ *else").hasMatch(val)) debug = false;
    if (buffer == null) buffer = false;
  }

  String toString() => val;
}

class _Comment extends _Node {
  String val;

  _Comment([this.val, buffer]) {
    this.buffer = buffer;
  }
}

class _Doctype extends _Node {
  String val;
  _Doctype(this.val);
}

class Each extends _Node {
  Object obj;
  String val;
  String key;
  _Block block;
  _Node alternative;

  Each(this.obj, this.val, this.key, [this.block]);
}

class _Filter extends _Node {
  String name;
  _Block block;
  Map attrs;

  _Filter(this.name, this.block, this.attrs);
}

class _Literal extends _Node {
  String str;
  _Literal(this.str);
}

class _Mixin extends _Tag {
  String name;
  String args;
  _Block block;
  bool call = false;
  List attrs = [];

  _Mixin([this.name, this.args, this.block, this.call]);
}

class _Tag extends _Attrs {
  String name;
  _Block block;
  List attrs = [];
  bool selfClosing = false;
  _Code code;

  _Tag([this.name, this.block]) {
    if (block == null) block = _Block();
  }

  _Tag clone() {
    return _Tag(name, block.clone())
      ..line = line
      ..attrs = attrs
      ..textOnly = textOnly;
  }

  bool get isInline => _inlineTags.contains(name);

  bool canInline() {
    var nodes = block.nodes;

    bool isInline(_Node node) {
      // Recurse if the node is a block
      if (node.is_Block) return (node as _Block).nodes.every(isInline);
      return node.is_Text || (node.isInline);
    }

    // Empty tag
    if (nodes.length == 0) return true;

    // _Text-only or inline-only tag
    if (1 == nodes.length) return isInline(nodes[0]);

    // Multi-line inline-only tag
    if (block.nodes.every(isInline)) {
      for (var i = 1, len = nodes.length; i < len; ++i) {
        if (nodes[i - 1].is_Text && nodes[i].is_Text) return false;
      }
      return true;
    }

    // Mixed tag
    return false;
  }

  String get label => "$runtimeType: <$name${selfClosing ? '/' : '></$name>'}";
}

class _Text extends _Node {
  String val = '';
  bool is_Text = true;

  _Text(line) {
    if (line is String) {val = line;}
  }

  String toString() => val;
}
