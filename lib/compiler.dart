part of jaded;

class AttrsTuple {
  String buf;
  String escaped;
  bool inherits;
  bool constant;
}

class Compiler {
  Node node;
  bool hasCompiledDoctype = false;
  bool hasCompiledTag = false;
  bool pp = false;
  String filename;
  bool escape = false;
  bool debug = false;
  int indents = 0;
  int parentIndents = 0;
  List buf;
  int lastBufferedIdx;
  String doctype;
  bool terse = false;
  bool xml = false;
  String lastBufferedType;
  String lastBuffered;
  String bufferStartChar;
  bool autoSemicolons;
  Function addVarReference;

  bool withinCase = false;

  Compiler(this.node, {
    bool pretty:false,
    bool compileDebug:false,
    this.doctype:null,
    this.filename,
    this.autoSemicolons:true})
  {
    hasCompiledDoctype = false;
    hasCompiledTag = false;
    pp = pretty;
    debug = compileDebug;
    indents = 0;
    parentIndents = 0;
    if (doctype != null) setDoctype(doctype);
    addVarReference = (str) =>
        throw new UnimplementedError("addVarReference");
  }

  String compile(){
    buf = [];
    if (pp) buf.add("jade.indent = [];");
    lastBufferedIdx = -1;
    visit(node);
    return buf.join('\n');
  }

  void setDoctype([String name="default"]){
    doctype = or(doctypes[name.toLowerCase()], '<!DOCTYPE $name>');
    terse = doctype.toLowerCase() == '<!doctype html>';
    xml = 0 == doctype.indexOf('<?xml');
  }

  void buffer(String str, [interpolate=false]) {
    if (interpolate) {
      Match match = str != null ? new RegExp(r"(\\)?([#!]){((?:.|\n)*)$").firstMatch(str) : null;
      if (match != null) {
        buffer(str.substring(0, match.start), false);
        if (match.group(1) != null) { // escape
          buffer(match.group(2) + '{', false);
          buffer(match.group(3), true);
          return;
        } else {
          String rest;
          String code;
          SrcPosition range;
          try {
            rest = match.group(3);
            range = parseJSExpression(rest);
            code = ('!' == match.group(2) ? '' : 'jade.escape') + "((jade.interp = ${range.src}) == null ? '' : jade.interp)";
            if (_isVarExpr(range.src)){
              addVarReference(range.src);
            }
          } catch (ex) {
            throw ex;
            //didn't match, just as if escaped
            buffer(match.group(2) + '{', false);
            buffer(match.group(3), true);
            return;
          }
          bufferExpression(code);
          buffer(rest.substring(range.end + 1), true);
          return;
        }
      }
    }

    str = CONV.JSON.encode(str);
    str = str.substring(1, str.length - 1);

    if (lastBufferedIdx == buf.length) {
      if (lastBufferedType == 'code') lastBuffered += ' + "';
      lastBufferedType = 'text';
      lastBuffered += str;
      buf[lastBufferedIdx - 1] = 'buf.add(${bufferStartChar + lastBuffered}");';
    } else {
      buf.add('buf.add("$str");');
      lastBufferedType = 'text';
      bufferStartChar = '"';
      lastBuffered = str;
      lastBufferedIdx = buf.length;
    }
  }

  void bufferExpression(String src) {
    if (lastBufferedIdx == buf.length) {
      if (lastBufferedType == 'text') lastBuffered += '"';
      lastBufferedType = 'code';
      lastBuffered += ' + (' + src + ')';
      buf[lastBufferedIdx - 1] = 'buf.add(${bufferStartChar + lastBuffered});';
    } else {
      buf.add('buf.add($src);');
      lastBufferedType = 'code';
      bufferStartChar = '';
      lastBuffered = '($src)';
      lastBufferedIdx = buf.length;
    }
  }

  void prettyIndent([offset=0, newline=false]){
    buffer((newline ? '\n' : '') + new List.filled(indents + offset, '').join('  '));
    if (parentIndents > 0){
      buf.add("jade.indent.forEach((x) => buf.add(x));");
    }
  }

  void visit(Node node){
    if (debug) {
      var filename = node.filename != null ? CONV.JSON.encode(node.filename) : 'jade.debug[0].filename';
      buf.add('jade.debug.insert(0, new Debug(lineno: ${node.line}, filename: $filename));');
    }

    // Massive hack to fix our context
    // stack for - else[ if] etc
    if (false == node.debug && debug) {
      buf.removeLast();
      buf.removeLast();
    }

    visitNode(node);

    if (debug) buf.add('jade.debug.removeAt(0);');
  }

  visitNode(Node node){
    var name = MirrorSystem.getName(reflect(node).type.simpleName);
    var method = new Symbol('visit' + name);
    InstanceMirror im = reflect(this);
    try {
      return im.invoke(method, [node]);
    } catch (e){
      print("Err: in visit$name: $e");
      return im.invoke(method, [node]);
    }
  }

  void visitCase(Case node){
    var _ = withinCase;
    withinCase = true;
    buf.add('switch (${node.expr}){');
    visit(node.block);
    buf.add('}');
    withinCase = _;
  }

  void visitWhen(When node){
    buf.add('default' == node.expr ? 'default:' : 'case ${node.expr}:');
    visit(node.block);
    buf.add('  break;');
  }

  void visitLiteral(Literal node) => buffer(node.str);

  void visitBlock(Block block){
    var len = block.nodes.length;

    // Block keyword has a special meaning in mixins
    if (parentIndents > 0 && block.mode != null) {
      if (pp) buf.add("jade.indent.add('${new List.filled(indents + 1,'').join('  ')}');");
      buf.add('if (block != null) block();');
      if (pp) buf.add("jade.indent.removeLast();");
      return;
    }

    // Pretty print multi-line text
    if (pp && len > 1 && !escape && block.nodes[0].isText && block.nodes[1].isText)
      prettyIndent(1, true);

    for (var i = 0; i < len; ++i) {
      // Pretty print text
      if (pp && i > 0 && !escape && block.nodes[i].isText && block.nodes[i-1].isText)
        prettyIndent(1, false);

      visit(block.nodes[i]);
      // Multiple text nodes are separated by newlines
      if (block.nodes.length > i+1 && block.nodes[i].isText && block.nodes[i+1].isText)
        buffer('\n');
    }
  }

  void visitDoctype([Doctype doctype]){
    if (doctype != null && (doctype.val != null || this.doctype == null)) {
      setDoctype(doctype.val != null && doctype.val != null ? doctype.val : 'default');
    }

    if (this.doctype != null) buffer(this.doctype);
    hasCompiledDoctype = true;
  }

  void visitMixin(Mixin mixin){
    var name = mixin.name.replaceAll("-", '_') + '_mixin';
    String args = or(mixin.args , '');
    Block block = mixin.block;
    List attrs = mixin.attrs;

    if (mixin.call) {
      if (pp) buf.add("jade.indent.add('${new List.filled(indents + 1, '').join('  ')}');");
      if (block != null || attrs.length > 0) {

        buf.add('$name({');

        if (block != null) {
          buf.add('"block": (){');

          // Render block with no indents, dynamically added when rendered
          parentIndents++;
          var _indents = indents;
          indents = 0;
          visit(mixin.block);
          indents = _indents;
          parentIndents--;

          if (attrs.length > 0) {
            buf.add('},');
          } else {
            buf.add('}');
          }
        }

        if (attrs.length > 0) {
          var val = this.attrs(attrs);
          if (val.inherits) {
            buf.add('"attributes": jade.merge({' + val.buf
                + '}, attributes), "escaped": jade.merge(' + val.escaped + ', escaped, true)');
          } else {
            buf.add('"attributes": {' + val.buf + '}, "escaped": ' + val.escaped);
          }
        }

        if (args != null && args.isNotEmpty) {
          buf.add('}, $args);');
        } else {
          buf.add('});');
        }

      } else {
        buf.add('$name(${args.isEmpty ? "{}" : "{},$args"});');
      }
      if (pp) buf.add("jade.indent.removeLast();");
    } else {
      buf
       ..add('$name = (${args.isEmpty ? "self" : "self,[$args]"}){')
       ..add('var block = self["block"], attributes = self["attributes"], escaped = self["escaped"];')
       ..add('if (attributes == null) attributes = {};')
       ..add('if (escaped == null) escaped = {};');

      parentIndents++;
      visit(block);
      parentIndents--;
      buf.add('};');
    }
  }

  void visitTag(Tag tag){
    indents++;
    var name = tag.name;

    bufferName() {
      if (tag.buffer) bufferExpression(name);
      else buffer(name);
    }

    if (!hasCompiledTag) {
      if (!hasCompiledDoctype && 'html' == name) {
        visitDoctype();
      }
      hasCompiledTag = true;
    }

    // pretty print
    if (pp && !tag.isInline)
      prettyIndent(0, true);

    if ((selfClosing.contains(name) || tag.selfClosing) && !xml) {
      buffer('<');
      bufferName();
      visitAttributes(tag.attrs);
      terse
        ? buffer('>')
        : buffer('/>');
    } else {
      // Optimize attributes buffering
      if (tag.attrs.length > 0) {
        buffer('<');
        bufferName();
        if (tag.attrs.length > 0) visitAttributes(tag.attrs);
        buffer('>');
      } else {
        buffer('<');
        bufferName();
        buffer('>');
      }
      if (tag.code != null) visitCode(tag.code);
      escape = 'pre' == tag.name;
      visit(tag.block);

      // pretty print
      if (pp && !tag.isInline && 'pre' != tag.name && !tag.canInline()){
        prettyIndent(0, true);
      }

      buffer('</');
      bufferName();
      buffer('>');
    }
    indents--;
  }

  void visitFilter(Filter nodeFilter){
    var text = nodeFilter.block.nodes.map((node) => node.val).join('\n');
    if (nodeFilter.attrs == null) nodeFilter.attrs = {};
    nodeFilter.attrs['filename'] = filename;
    this.buffer(filter(nodeFilter.name, text, nodeFilter.attrs), true);
  }

  visitText(Text text) =>
    buffer(text.val, true);

  visitComment(Comment comment){
    if (!comment.buffer) return;
    if (pp) prettyIndent(1, true);
    buffer('<!--${comment.val}-->');
  }

  visitBlockComment(BlockComment comment){
    if (!comment.buffer) return;
    if (0 == comment.val.trim().indexOf('if')) {
      buffer('<!--[${comment.val.trim()}]>');
      visit(comment.block);
      buffer('<![endif]-->');
    } else {
      buffer('<!--${comment.val}');
      visit(comment.block);
      buffer('-->');
    }
  }

  visitCode(Code code){
    // Wrap code blocks with {}.
    // we only wrap unbuffered code blocks ATM
    // since they are usually flow control

    // Buffer code
    if (code.buffer) {
      var val = trimLeft(code.val);
      val = 'null == (jade.interp = $val) ? "" : jade.interp';
      if (code.escape) val = 'jade.escape($val)';
      this.bufferExpression(val);
    } else {
      var stmt = code.val;
      var cmp = code.val.trim();
      if (autoSemicolons && !cmp.endsWith(";") && !cmp.endsWith("{")) {
        var firstToken = code.val.trim().split(" ")[0];
        if (firstToken == "var" || !isKeyword(firstToken))
          stmt += ";";
      }
      this.buf.add(stmt);
    }

    // Block support
    if (code.block != null) {
      if (!code.buffer) this.buf.add('{');
      this.visit(code.block);
      if (!code.buffer) this.buf.add('}');
    }
  }

  visitEach(Each each){
    var obj = r"$$obj";
    var l = r"$$l";
    buf.add(''
      + '// iterate ' + each.obj + '\n'
      + ';((){\n'
      + '  var $obj = ${each.obj};\n'
      + '  if ($obj is Iterable) {\n');

    if (each.alternative != null) {
      buf.add('  if ($obj != null && !$obj.isEmpty) {');
    }

    buf.add(''
      + '    for (var ${each.key} = 0, $l = $obj.length; ${each.key} < $l; ${each.key}++) {\n'
      + '      var ${each.val} = $obj[${each.key}];\n');

    visit(each.block);

    buf.add('    }\n');

    if (each.alternative != null) {
      buf.add('  } else {');
      visit(each.alternative);
      buf.add('  }');
    }

    buf.add(''
      + '  } else {\n'
      + '    var $l = 0;\n'
      + '    for (var ${each.key} in ${obj}.keys) {\n'
      + '      $l++;'
      + '      var ${each.val} = $obj[${each.key}];\n');

    visit(each.block);

    buf.add('    }\n');
    if (each.alternative != null) {
      buf.add('    if ($l == 0) {');
      visit(each.alternative);
      buf.add('    }');
    }
    buf.add('  }\n})();\n'); //buf.add('  }\n}).call(this);\n');
  }

  visitAttributes(List attrs){
    if (attrs.isEmpty) return; //DB: avoid eval with NO OPs

    var val = this.attrs(attrs);
    if (val.inherits) {
      bufferExpression("jade.attrs(jade.merge({ ${val.buf} }, attributes), jade.merge(${val.escaped}, escaped, true))");
    } else if (val.constant) {
      buffer(jade.attrs(fakeEval("{ ${val.buf} }"), CONV.JSON.decode(val.escaped)));

//      throw new ParseError("eval not supported");
//      eval('var evalBuf={' + val.buf + '};');
//      buffer(jade.attrs(evalBuf, JSON.parse(val.escaped)));
    } else {
      this.bufferExpression("jade.attrs({ ${val.buf} }, ${val.escaped})");
    }
  }

  fakeEval(String str){
    var fakeJsonStr = str
      .replaceAll('"{','{')
      .replaceAll('}"','}')
      .replaceAll(r"\#", "#");

    var sb = new StringBuffer();
    bool inQuotes = false;
    String lastQuote = null;
    String lastChar = null;
    for (var c in fakeJsonStr.split(''))
    {
      if (!inQuotes)
      {
        if (c == '(' || c == ')') continue; //remove '()' outside quotes
      }
      else
      {
        if ((lastQuote == '"' && c == "'") || (lastQuote == "'" && c == '"')) {
          if (c == "\"") sb.write('\\'); //escape quotes inside quotes
          sb.write(c);
          continue;
        }
      }
      if (c == '"' || c == "'") {
        inQuotes = !inQuotes;
        lastQuote = c;
        c = '"';
      }
      sb.write(c);
      lastChar = c;
    }
    fakeJsonStr = sb.toString();

    try {
      return CONV.JSON.decode(fakeJsonStr);
    } catch(e){
      print("Err parsing fakeEval: $fakeJsonStr / $str: $e");
      return {};
    }
  }

  AttrsTuple attrs(List attrs){
    var buf = [];
    var classes = [];
    var escaped = {};
    var constant = attrs.every((attr) => isConstant(attr.val));
    var inherits = false;

    if (this.terse) buf.add('"terse": true');

    attrs.forEach((attr){
      if (attr.name == 'attributes') return inherits = true;
      escaped[attr.name] = attr.escaped;
      if (attr.name == 'class') {
        classes.add('(${attr.val})');
      } else {
        var pair = "'${attr.name}':(${attr.val})";
        buf.add(pair);
      }
    });

    if (classes.length > 0) {
      buf.add('"class": [${classes.join(",")}]');
    }

    return new AttrsTuple()
      ..buf = buf.join(', ')
      ..escaped = CONV.JSON.encode(escaped)
      ..inherits = inherits
      ..constant = constant;
  }

  isConstant(val){
    // Check strings/literals
    if (new RegExp(r'^ *("([^"\\]*(\\.[^"\\]*)*)"'
        + r"|'([^'\\]*(\\.[^'\\]*)*)'|true|false|null) *$", caseSensitive:false)
      .hasMatch("$val"))
    return true;

    // Check numbers
    if (!double.parse(val, (x) => double.NAN).isNaN)
      return true;

    // Check arrays
    List<String> matches;
    if ((matches = exec(new RegExp(r"^ *\[(.*)\] *$"), val)) != null)
      return matches[1].split(',').every(isConstant);

    return false;
  }

}
