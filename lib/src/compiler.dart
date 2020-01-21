part of jaded;

//required for Mirror invocations while maintaining library privacy
//ignore_for_file: non_constant_identifier_names
class _AttrsTuple {
  String buf;
  String escaped;
  bool inherits;
  bool constant;
}

class _Compiler {
  _Node node;
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

  _Compiler(this.node,
      {bool pretty = false,
      bool compileDebug = false,
      this.doctype,
      this.filename,
      this.autoSemicolons = true}) {
    hasCompiledDoctype = false;
    hasCompiledTag = false;
    pp = pretty;
    debug = compileDebug;
    indents = 0;
    parentIndents = 0;
    if (doctype != null) {
      setDoctype(doctype);
    }
    addVarReference = (str) => throw UnimplementedError('addVarReference');
  }

  String compile() {
    buf = [];
    if (pp) {
      buf.add('jade.indent = [];');
    }
    lastBufferedIdx = -1;
    visit(node);
    return buf.join('\n');
  }

  void setDoctype([String name = 'default']) {
    doctype = or(_doctypes[name.toLowerCase()], '<!DOCTYPE $name>');
    terse = doctype.toLowerCase() == '<!doctype html>';
    xml = 0 == doctype.indexOf('<?xml');
  }

  void buffer(String str, {bool interpolate = false}) {
    if (interpolate) {
      Match match = str != null
          ? RegExp(r'(\\)?([#!]){((?:.|\n)*)$').firstMatch(str)
          : null;
      if (match != null) {
        buffer(str.substring(0, match.start), interpolate: false);
        if (match.group(1) != null) {
          // escape
          buffer('${match.group(2)}{', interpolate: false);
          buffer(match.group(3), interpolate: true);
          return;
        } else {
          String rest;
          String code;
          SrcPosition range;
          try {
            rest = match.group(3);
            range = _parseJSExpression(rest);
            code = '${('!' == match.group(2) ? '' : 'jade.escape')}'
                "((jade.interp = ${range.src}) == null ? '' : jade.interp)";
            if (_isVarExpr(range.src)) {
              addVarReference(range.src);
            }
          } on Exception {
            rethrow;
          }
          bufferExpression(code);
          buffer(rest.substring(range.end + 1), interpolate: true);
          return;
        }
      }
    }

    str = conv.json.encode(str);
    str = str.substring(1, str.length - 1);

    if (lastBufferedIdx == buf.length) {
      if (lastBufferedType == 'code') {
        lastBuffered += ' + "';
      }
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
      if (lastBufferedType == 'text') {
        lastBuffered += '"';
      }
      lastBufferedType = 'code';
      lastBuffered += ' + ($src)';
      buf[lastBufferedIdx - 1] = 'buf.add(${bufferStartChar + lastBuffered});';
    } else {
      buf.add('buf.add($src);');
      lastBufferedType = 'code';
      bufferStartChar = '';
      lastBuffered = '($src)';
      lastBufferedIdx = buf.length;
    }
  }

  void prettyIndent({int offset = 0, bool newline = false}) {
    buffer(
        (newline ? '\n' : '') + List.filled(indents + offset, '').join('  '));
    if (parentIndents > 0) {
      buf.add('jade.indent.forEach((x) => buf.add(x));');
    }
  }

  void visit(_Node node) {
    if (debug) {
      var filename = node.filename != null
          ? conv.json.encode(node.filename)
          : 'jade.debug[0].filename';
      buf.add(
          '''jade.debug.insert(0, new Debug(lineno: ${node.line}, filename: $filename));''');
    }

    // Massive hack to fix our context
    // stack for - else[ if] etc
    if (false == node.debug && debug) {
      buf.removeLast();
      buf.removeLast();
    }

    _visit_Node(node);

    if (debug) {
      buf.add('jade.debug.removeAt(0);');
    }
  }

  InstanceMirror _visit_Node(_Node node) {
    var name = MirrorSystem.getName(reflect(node).type.simpleName);
    var method = Symbol('visit$name');
    var im = reflect(this);
    try {
      return im.invoke(method, [node]);
    } on Exception catch (e) {
      print('Err: in visit$name: $e');
      return im.invoke(method, [node]);
    }
  }

  void visit_Case(_Case node) {
    var _ = withinCase;
    withinCase = true;
    buf.add('switch (${node.expr}){');
    visit(node.block);
    buf.add('}');
    withinCase = _;
  }

  void visit_When(_When node) {
    buf.add('default' == node.expr ? 'default:' : 'case ${node.expr}:');
    visit(node.block);
    buf.add('  break;');
  }

  void visit_Literal(_Literal node) => buffer(node.str);

  void visit_Block(_Block block) {
    var len = block.nodes.length;

    // _Block keyword has a special meaning in mixins
    if (parentIndents > 0 && block.mode != null) {
      if (pp) {
        buf.add(
            "jade.indent.add('${List.filled(indents + 1, '').join('  ')}');");
      }
      buf.add('if (block != null) {block();}');
      if (pp) {
        buf.add('jade.indent.removeLast();');
      }
      return;
    }

    // Pretty print multi-line text
    if (pp &&
        len > 1 &&
        !escape &&
        block.nodes[0].is_Text &&
        block.nodes[1].is_Text) {
      prettyIndent(offset: 1, newline: true);
    }

    for (var i = 0; i < len; ++i) {
      // Pretty print text
      if (pp &&
          i > 0 &&
          !escape &&
          block.nodes[i].is_Text &&
          block.nodes[i - 1].is_Text) {
        prettyIndent(offset: 1, newline: false);
      }

      visit(block.nodes[i]);
      // Multiple text nodes are separated by newlines
      if (block.nodes.length > i + 1 &&
          block.nodes[i].is_Text &&
          block.nodes[i + 1].is_Text) {
        buffer('\n');
      }
    }
  }

  void visit_Doctype([_Doctype doctype]) {
    if (doctype != null && (doctype.val != null || this.doctype == null)) {
      setDoctype(
          doctype.val != null && doctype.val != null ? doctype.val : 'default');
    }

    if (this.doctype != null) {
      buffer(this.doctype);
    }
    hasCompiledDoctype = true;
  }

  void visit_Mixin(_Mixin mixin) {
    var name = '${mixin.name.replaceAll("-", '_')}_mixin';
    String args = or(mixin.args, '');
    var block = mixin.block;
    var attrs = mixin.attrs;

    if (mixin.call) {
      if (pp) {
        buf.add(
            "jade.indent.add('${List.filled(indents + 1, '').join('  ')}');");
      }
      if (block != null || attrs.isNotEmpty) {
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

          if (attrs.isNotEmpty) {
            buf.add('},');
          } else {
            buf.add('}');
          }
        }

        if (attrs.isNotEmpty) {
          var val = this.attrs(attrs);
          if (val.inherits) {
            buf.add('''
            "attributes": jade.merge({${val.buf}}, attributes), "escaped": jade.merge(${val.escaped}, escaped, true)''');
          } else {
            buf.add('"attributes": {${val.buf}}, "escaped": ${val.escaped}');
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
      if (pp) {
        buf.add('jade.indent.removeLast();');
      }
    } else {
      buf
        ..add('$name = (${args.isEmpty ? "self" : "self,[$args]"}){')
        ..add('''
        var block = self["block"], attributes = self["attributes"], escaped = self["escaped"];''')
        ..add('if (attributes == null) {attributes = {};}')
        ..add('if (escaped == null) {escaped = {};}');

      parentIndents++;
      visit(block);
      parentIndents--;
      buf.add('};');
    }
  }

  void visit_Tag(_Tag tag) {
    indents++;
    var name = tag.name;

    void bufferName() {
      if (tag.buffer) {
        bufferExpression(name);
      } else {
        buffer(name);
      }
    }

    if (!hasCompiledTag) {
      if (!hasCompiledDoctype && 'html' == name) {
        visit_Doctype();
      }
      hasCompiledTag = true;
    }

    // pretty print
    if (pp && !tag.isInline) {
      prettyIndent(offset: 0, newline: true);
    }

    if ((_selfClosing.contains(name) || tag.selfClosing) && !xml) {
      buffer('<');
      bufferName();
      visitAttributes(tag.attrs);
      terse ? buffer('>') : buffer('/>');
    } else {
      // Optimize attributes buffering
      if (tag.attrs.isNotEmpty) {
        buffer('<');
        bufferName();
        if (tag.attrs.isNotEmpty) {
          visitAttributes(tag.attrs);
        }
        buffer('>');
      } else {
        buffer('<');
        bufferName();
        buffer('>');
      }
      if (tag.code != null) {
        visit_Code(tag.code);
      }
      escape = 'pre' == tag.name;
      visit(tag.block);

      // pretty print
      if (pp && !tag.isInline && 'pre' != tag.name && !tag.canInline()) {
        prettyIndent(offset: 0, newline: true);
      }

      buffer('</');
      bufferName();
      buffer('>');
    }
    indents--;
  }

  void visit_Filter(_Filter node_Filter) {
    var text = node_Filter.block.nodes.map((node) => node.val).join('\n');
    node_Filter.attrs ??= {};
    node_Filter.attrs['filename'] = filename;
    buffer(_filter(node_Filter.name, text, node_Filter.attrs),
        interpolate: true);
  }

  void visit_Text(_Text text) => buffer(text.val, interpolate: true);

  void visit_Comment(_Comment comment) {
    if (!comment.buffer) {
      return;
    }
    if (pp) {
      prettyIndent(offset: 1, newline: true);
    }
    buffer('<!--${comment.val}-->');
  }

  void visit_Block_Comment(_Block_Comment comment) {
    if (!comment.buffer) {
      return;
    }
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

  void visit_Code(_Code code) {
    // Wrap code blocks with {}.
    // we only wrap unbuffered code blocks ATM
    // since they are usually flow control

    // Buffer code
    if (code.buffer) {
      var val = trimLeft(code.val);
      val = 'null == (jade.interp = $val) ? "" : jade.interp';
      if (code.escape) {
        val = 'jade.escape($val)';
      }
      bufferExpression(val);
    } else {
      var stmt = code.val;
      var cmp = code.val.trim();
      if (autoSemicolons && !cmp.endsWith(';') && !cmp.endsWith('{')) {
        var firstToken = code.val.trim().split(' ')[0];
        if (firstToken == 'var' || !isKeyword(firstToken)) {
          stmt += ';';
        }
      }
      buf.add(stmt);
    }

    // _Block support
    if (code.block != null) {
      if (!code.buffer) {
        buf.add('{');
      }
      visit(code.block);
      if (!code.buffer) {
        buf.add('}');
      }
    }
  }

  void visit_Each(_Each each) {
    var obj = r'$$obj';
    var l = r'$$l';
    buf.add(''
        '// iterate '
        '${each.obj}'
        '\n'
        'try{\n'
        ';((){\n'
        '  var $obj = ${each.obj};\n'
        '  if ($obj is Iterable) {\n');

    if (each.alternative != null) {
      buf.add('  if ($obj != null && !$obj.isEmpty) {');
    }

    buf.add(''
        '    for (var ${each.key} = 0, $l = $obj.length;'
        '${each.key} < $l; ${each.key}++) {\n'
        '      var ${each.val} = $obj.elementAt(${each.key});\n');

    visit(each.block);

    buf.add('    }\n');

    if (each.alternative != null) {
      buf.add('  } else {');
      visit(each.alternative);
      buf.add('  }');
    }

    buf.add(''
        '   } else {\n'
        '     var $l = 0;\n'
        '     for (var ${each.key} in ${obj}.keys) {\n' //ignore: unnecessary_brace_in_string_interps
        '       $l++;'
        '       var ${each.val} = $obj[${each.key}];\n');

    visit(each.block);

    buf.add('    }\n');
    if (each.alternative != null) {
      buf.add('    if ($l == 0) {');
      visit(each.alternative);
      buf.add('    }');
    }
    buf.add(
        '  }\n})();\n} catch(e){\nprint("");\n}'); //buf.add('  }\n}).call(this);\n');
  }

  void visitAttributes(List attrs) {
    if (attrs.isEmpty) {
      return;
    } //DB: avoid eval with NO OPs

    var val = this.attrs(attrs);
    if (val.inherits) {
      bufferExpression('''
          jade.attrs(jade.merge({ ${val.buf} }, attributes), jade.merge(${val.escaped}, escaped, true))''');
    } else if (val.constant) {
      buffer(jade.attrs(
          fakeEval('{ ${val.buf} }'), conv.json.decode(val.escaped)));

//      throw new ParseError("eval not supported");
//      eval('var evalBuf={' + val.buf + '};');
//      buffer(jade.attrs(evalBuf, json.parse(val.escaped)));
    } else {
      bufferExpression('jade.attrs({ ${val.buf} }, ${val.escaped})');
    }
  }

  dynamic fakeEval(String str) {
    var fakeJsonStr =
        str.replaceAll('"{', '{').replaceAll('}"', '}').replaceAll(r'\#', '#');

    var sb = StringBuffer();
    var inQuotes = false;
    var lastQuote;
    var lastChar; //ignore: unused_local_variable
    for (var c in fakeJsonStr.split('')) {
      if (!inQuotes) {
        if (c == '(' || c == ')') {
          continue;
        } //remove '()' outside quotes
      } else {
        if ((lastQuote == '"' && c == "'") || (lastQuote == "'" && c == '"')) {
          if (c == '\"') {
            sb.write('\\');
          } //escape quotes inside quotes
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
      return conv.json.decode(fakeJsonStr);
    } on Exception catch (e) {
      print('Err parsing fakeEval: $fakeJsonStr / $str: $e');
      return {};
    }
  }

  _AttrsTuple attrs(List attrs) {
    var buf = [];
    var classes = [];
    var escaped = {};
    var constant =
        attrs.every((attr) => isConstant(attr.val is String ? attr.val : null));
    var inherits = false;

    if (terse) {
      buf.add('"terse": true');
    }

    dynamic _feFunc(attr) {
      if (attr.name == 'attributes') {
        return inherits = true;
      }
      escaped[attr.name] = attr.escaped;
      if (attr.name == 'class') {
        classes.add('(${attr.val})');
      } else {
        var pair = "'${attr.name}':(${attr.val})";
        buf.add(pair);
      }
    }

    attrs.forEach(_feFunc);

    if (classes.isNotEmpty) {
      buf.add('"class": [${classes.join(",")}]');
    }

    return _AttrsTuple()
      ..buf = buf.join(', ')
      ..escaped = conv.json.encode(escaped)
      ..inherits = inherits
      ..constant = constant;
  }

  bool isConstant(String val) {
    // Check strings/literals
    if (RegExp(
            r'^ *("([^"\\]*(\\.[^"\\]*)*)"'
            r"|'([^'\\]*(\\.[^'\\]*)*)'|true|false|null) *$",
            caseSensitive: false)
        .hasMatch('$val')) {
      return true;
    }

    // Check numbers
    if (double.tryParse(val) != null && double.tryParse(val).isNaN) {
      return true;
    } else {
      (val) => double.nan;
    }
    // Check arrays
    List<String> matches;
    if ((matches = exec(RegExp(r'^ *\[(.*)\] *$'), val)) != null) {
      return matches[1].split(',').every(isConstant);
    }

    return false;
  }
}
