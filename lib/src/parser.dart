part of jaded;

var _textOnly = const ['script', 'style'];

class _Parser {
  String input;
  String filename;
  String basedir;
  bool colons;
  _Lexer lexer;
  Map<String, _Block> blocks = {};
  Map<String, _Mixin> mixins = {};
  List contexts;
  _Parser extending;
  _Parser _root;
  _Parser get root => (_root != null ? _root : this);

  int _spaces;

  _Parser(this.input, {this.filename, this.basedir, this.colons}) {
    lexer = _Lexer(input, colons: colons);
    contexts = [this];
  }

  _Parser create_Parser(str,
          {String filename, String basedir, bool colons = false}) =>
      _Parser(str, filename: filename, basedir: basedir, colons: colons)
        .._root = root;

  List<dynamic> undeclaredVarReferences() {
    var ret = [];
    for (var ref in lexer.varReferences) {
      if (!lexer.varDeclarations.contains(ref)) ret.add(ref);
    }
    return ret;
  }

  List<String> get varDeclarations => lexer.varDeclarations;

  _Parser context([_Parser parser]) {
    if (parser != null) {
      contexts.add(parser);
    } else {
      return contexts.removeLast();
    }
    return null;
  }

  _Token advance() => lexer.advance();

  void skip(int n) {
    while (n-- > 0) {advance();}
  }

  _Token peek() => lookahead(1);

  int line() => lexer.lineno;

  _Token lookahead(dynamic n) => lexer.lookahead(n);

  _Block parse() {
    var parser;
    var block = _Block()..line = line();

    while ('eos' != peek().type) {
      if ('newline' == peek().type) {
        advance();
      } else {
        block.add(parseExpr());
      }
    }

    if ((parser = extending) != null) {
      context(parser);
      var ast = parser.parse();
      context();

      // hoist mixins
      for (var name in mixins.keys) ast.unshift(mixins[name]);
      return ast;
    }

    return block;
  }

  expect(type) {
    if (peek().type == type) {
      return advance();
    } else {
      throw ParseError('expected "$type", but got "${peek().type}"');
    }
  }

  accept(type) => peek().type == type ? advance() : null;

  parseExpr() {
    switch (peek().type) {
      case 'tag':
        return parse_Tag();
      case 'mixin':
        return parse_Mixin();
      case 'block':
        return parse_Block();
      case 'case':
        return parse_Case();
      case 'when':
        return parse_When();
      case 'default':
        return parseDefault();
      case 'extends':
        return parseExtends();
      case 'include':
        return parseInclude();
      case 'doctype':
        return parse_Doctype();
      case 'filter':
        return parse_Filter();
      case 'comment':
        return parse_Comment();
      case 'text':
        return parse_Text();
      case 'each':
        return parseEach();
      case 'code':
        return parse_Code();
      case 'call':
        return parseCall();
      case 'interpolation':
        return parseInterpolation();
      case 'yield':
        advance();
        var block = _Block();
        block.yield = true;
        return block;
      case 'id':
      case 'class':
        var tok = advance();
        lexer.defer(lexer.tok('tag', 'div'));
        lexer.defer(tok);
        return parseExpr();
      default:
        throw ParseError('unexpected token "${peek().type}"');
    }
  }

  _Text parse_Text() => _Text(expect('text').val)..line = line();

  _Block parse_BlockExpansion() {
    if (':' == peek().type) {
      advance();
      return _Block(parseExpr());
    }
    return block();
  }

  _Case parse_Case() => _Case(expect('case').val)
    ..line = line()
    ..block = block();

  _When parse_When() => _When(expect('when').val, parse_BlockExpansion());

  _When parseDefault() {
    expect('default');
    return _When('default', parse_BlockExpansion());
  }

  _Code parse_Code() {
    var tok = expect('code');
    var node = _Code(tok.val, tok.buffer, tok.escape)..line = line();
    var i = 1;
    while (lookahead(i) != null && 'newline' == lookahead(i).type) ++i;
    var _block = 'indent' == lookahead(i).type;
    if (_block) {
      skip(i - 1);
      node.block = block();
    }
    return node;
  }

  _Node parse_Comment() {
    var tok = expect('comment');
    _Node node = 'indent' == peek().type
        ? _Block_Comment(tok.val, block(), tok.buffer)
        : _Comment(tok.val, tok.buffer);

    node.line = line();
    return node;
  }

  _Doctype parse_Doctype() => _Doctype(expect('doctype').val)..line = line();

  _Filter parse_Filter() {
    var tok = expect('filter');
    var attrs = accept('attrs');

    lexer.pipeless = true;
    var block = parse_Text_Block();
    lexer.pipeless = false;

    return _Filter(tok.val, block, attrs != null ? attrs.attrs : null)
      ..line = line();
  }

  Each parseEach() {
    var tok = expect('each');
    var node = Each(tok.code, tok.val, tok.key)
      ..line = line()
      ..block = block();
    if (peek().type == 'code' && peek().val == 'else') {
      advance();
      node.alternative = block();
    }
    return node;
  }

  String resolvePath(String path, purpose) {
    if (path[0] != '/' && filename == null)
      throw ParseError(
          'the "filename" option is required to use "$purpose" with "relative" paths');

    if (path[0] == '/' && basedir == null)
      throw ParseError(
          'the "basedir" option is required to use "$purpose" with "absolute" paths');

    path = join([path[0] == '/' ? basedir : dirname(filename), path]);

    if (basename(path).indexOf('.') == -1) path += '.jade';

    return path;
  }

  _Literal parseExtends() {
    var path = resolvePath(expect('extends').val.trim(), 'extends');
    if ('.jade' != path.substring(path.length - 5)) path += '.jade';

    var str = File(path).readAsStringSync();
    var parser =
        create_Parser(str, filename: path, basedir: basedir, colons: colons);

    parser.blocks = blocks;
    parser.contexts = contexts;
    extending = parser;

    // TODO: null node
    return _Literal('');
  }

  _Block parse_Block() {
    var _block = expect('block');
    var mode = _block.mode;
    var name = _block.val.trim();

    _block = 'indent' == peek().type ? block() : _Block(_Literal(''));

    _Block prev = or(blocks[name], () => _Block());
    if (prev.mode == 'replace') return blocks[name] = prev;

    var all_Nodes = prev.prepended.toList()
      ..addAll(_block.nodes)
      ..addAll(prev.appended);

    switch (mode) {
      case 'append':
        prev.appended = prev.parser == this
            ? (prev.appended.toList()..addAll(_block.nodes))
            : (_block.nodes.toList()..addAll(prev.appended));
        break;
      case 'prepend':
        prev.prepended = prev.parser == this
            ? (_block.nodes.toList()..addAll(prev.prepended))
            : (prev.prepended.toList()..addAll(_block.nodes));
        break;
    }
    _block
      ..nodes = all_Nodes
      ..appended = prev.appended
      ..prepended = prev.prepended
      ..mode = mode
      ..parser = this;

    return blocks[name] = _block;
  }

  _Node parseInclude() {
    var path = resolvePath(expect('include').val.trim(), 'include');

    // non-jade
    var str = File(path).readAsStringSync();
    if ('.jade' != path.substring(path.length - 5, path.length)) {
      str = str.replaceAll(RegExp(r"\r"), '');
      var ext = extname(path).substring(1);
      if (_filterExists(ext)) {str = _filter(ext, str, {"filename": path});}
      return _Literal(str);
    }

    var parser =
        create_Parser(str, filename: path, basedir: basedir, colons: colons);
    parser.blocks = merge(<String, _Block>{}, blocks);

    parser.mixins = mixins;

    context(parser);
    var ast = parser.parse();
    context();
    ast.filename = path;

    if ('indent' == peek().type) {
      ast.include_Block().add(block());
    }

    return ast;
  }

  _Mixin parseCall() {
    var tok = expect('call');
    var name = tok.val;
    var args = tok.args;
    var mixin = _Mixin(name, args, _Block(), true);

    tag(mixin);
    if (mixin.code != null) {
      mixin.block.add(mixin.code);
      mixin.code = null;
    }
    if (mixin.block.isEmpty) mixin.block = null;
    return mixin;
  }

  _Mixin parse_Mixin() {
    var tok = expect('mixin');
    var name = tok.val;
    var args = tok.args;
    var mixin;

    // definition
    if ('indent' == peek().type) {
      //DB: mixins can be overwritten
      root.lexer.addVarDeclaration(name + "_mixin");

      mixin = _Mixin(name, args, block(), false);
      mixins[name] = mixin;
      return mixin;
      // call
    } else {
      return _Mixin(name, args, null, true);
    }
  }

  _Block parse_Text_Block() {
    var block = _Block();
    block.line = line();
    var spaces = expect('indent').val;
    if (null == _spaces) _spaces = spaces;
    var indent = List.filled(spaces - _spaces + 1, '').join(' ');
    while ('outdent' != peek().type) {
      switch (peek().type) {
        case 'newline':
          advance();
          break;
        case 'indent':
          parse_Text_Block().nodes.forEach((node) {
            block.add(node);
          });
          break;
        default:
          var text = _Text(indent + advance().val);
          text.line = line();
          block.add(text);
      }
    }

    if (spaces == _spaces) _spaces = null;
    expect('outdent');
    return block;
  }

  _Block block() {
    var block = _Block();
    block.line = line();
    expect('indent');
    while ('outdent' != peek().type) {
      if ('newline' == peek().type) {
        advance();
      } else {
        block.add(parseExpr());
      }
    }
    expect('outdent');
    return block;
  }

  parseInterpolation() {
    var tok = advance();
    return tag(_Tag(tok.val)..buffer = true);
  }

  parse_Tag() {
    // ast-filter look-ahead
    var i = 2;
    if ('attrs' == lookahead(i).type) ++i;

    var _tok = advance();
    return tag(_Tag(_tok.val)..selfClosing = _tok.selfClosing);
  }

  tag(_Tag tag) {
    bool dot = false;

    tag.line = line();

    // (attrs | class | id)*
    out:
    while (true) {
      switch (peek().type) {
        case 'id':
        case 'class':
          var _tok = advance();
          tag.set_Attribute(_tok.type, "'${_tok.val}'");
          continue;
        case 'attrs':
          var _tok = advance();
          var obj = _tok.attrs;
          var escaped = _tok.escaped;
          var names = obj.keys;

          if (_tok.selfClosing) {tag.selfClosing = true;}

          for (var name in names) {
            var val = obj[name];
            tag.set_Attribute(name, val, escaped:escaped[name]);
          }
          continue;
        default:
          break out;
      }
    }

    // check immediate '.'
    if ('.' == peek().val) {
      dot = tag.textOnly = true;
      advance();
    }

    // (text | code | ':')?
    switch (peek().type) {
      case 'text':
        tag.block.add(parse_Text());
        break;
      case 'code':
        tag.code = parse_Code();
        break;
      case ':':
        advance();
        tag.block = _Block()..add(parseExpr());
        break;
    }

    // newline*
    while ('newline' == peek().type) advance();

    tag.textOnly = tag.textOnly || _textOnly.contains(tag.name);

    // script special-case
    if ('script' == tag.name) {
      var type = tag.get_Attribute('type');
      if (!dot &&
          type != null &&
          'text/javascript' != type.replaceAll(RegExp("^['\"]|['\"]\$"), '')) {
        tag.textOnly = false;
      }
    }

    // block?
    if ('indent' == peek().type) {
      if (tag.textOnly) {
        if (!dot) {
          logWarn('$filename, line ${peek().line}:');
          logWarn(
              'Implicit textOnly for `script` and `style` is deprecated.  Use `script.` or `style.` instead.');
        }
        lexer.pipeless = true;
        tag.block = parse_Text_Block();
        lexer.pipeless = false;
      } else {
        var _block = block();
        if (tag.block != null) {
          for (var node in _block.nodes) {
            tag.block.add(node);
          }
        } else {
          tag.block = _block;
        }
      }
    }

    return tag;
  }

  logWarn(String msg) => print(msg);
}
