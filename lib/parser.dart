part of jaded;

var textOnly = const ['script', 'style'];

class Parser {
  String input;
  String filename;
  Map options; //basedir
  Lexer lexer;
  Map<String,Block> blocks = {};
  Map<String,Mixin> mixins = {};
  List contexts;
  Parser extending;
  Parser _root;
  Parser get root => (_root != null ? _root : this);
  bool _hasWrittenVars = false;
  
  int _spaces;
    
  Parser([this.input, this.filename, this.options]){
    lexer = new Lexer(input, options);
    contexts = [this];
  }

  Parser createParser(str, path, options) => 
    new Parser(str, path, options)
      .._root = root;
  
  Parser context([Parser parser]){
    if (parser != null) {
      contexts.add(parser);
    } else {
      return contexts.removeLast();
    }
    return null;
  }

  Token advance() => lexer.advance();

  void skip(int n){
    while (n-- > 0) advance();
  }
  
  Token peek() => lookahead(1);
  
  int line() => lexer.lineno;

  Token lookahead(n) => lexer.lookahead(n);

  Block parse(){
    var parser;
    var block = new Block() 
      ..line = line();

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
      for (var name in mixins.keys)
        ast.unshift(mixins[name]);
      return ast;
    }

    //DB: register all var declarations at the top
    if (lexer.vars.length > 0 && !root._hasWrittenVars){
      block.nodes.insert(0, new Code("var ${lexer.vars.join(', ')};"));
      root._hasWrittenVars = true;
    }

    return block;
  }
  
  expect(type){
    if (peek().type == type) {
      return advance();
    } else {
      throw new ParseError('expected "$type", but got "${peek().type}"');
    }
  }

  accept(type) => peek().type == type ? advance() : null;
 
  parseExpr(){
    switch (peek().type) {
      case 'tag':
        return parseTag();
      case 'mixin':
        return parseMixin();
      case 'block':
        return parseBlock();
      case 'case':
        return parseCase();
      case 'when':
        return parseWhen();
      case 'default':
        return parseDefault();
      case 'extends':
        return parseExtends();
      case 'include':
        return parseInclude();
      case 'doctype':
        return parseDoctype();
      case 'filter':
        return parseFilter();
      case 'comment':
        return parseComment();
      case 'text':
        return parseText();
      case 'each':
        return parseEach();
      case 'code':
        return parseCode();
      case 'call':
        return parseCall();
      case 'interpolation':
        return parseInterpolation();
      case 'yield':
        advance();
        var block = new Block();
        block.yield = true;
        return block;
      case 'id':
      case 'class':
        var tok = advance();
        lexer.defer(lexer.tok('tag', 'div'));
        lexer.defer(tok);
        return parseExpr();
      default:
        throw new ParseError('unexpected token "${peek().type}"');
    }
  }  

  Text parseText() =>
    new Text(expect('text').val)
      ..line = line();
   
  Block parseBlockExpansion(){
    if (':' == peek().type) {
      advance();
      return new Block(parseExpr());
    } 
    return block();
  }
  
  Case parseCase() =>
    new Case(expect('case').val)
      ..line = line()
      ..block = block();
  
  When parseWhen() =>
    new When(expect('when').val, parseBlockExpansion());
   
  When parseDefault(){
    expect('default');
    return new When('default', parseBlockExpansion());
  }  
  
  Code parseCode(){
    var tok = expect('code');
    var node = new Code(tok.val, tok.buffer, tok.escape)
      ..line = line();
    var i = 1;
    while (lookahead(i) != null && 'newline' == lookahead(i).type) ++i;
    var _block = 'indent' == lookahead(i).type;
    if (_block) {
      skip(i-1);
      node.block = block();
    }
    return node;
  }  
  
  Node parseComment(){
    var tok = expect('comment');
    Node node = 'indent' == peek().type
      ? new BlockComment(tok.val, block(), tok.buffer)
      : new Comment(tok.val, tok.buffer);

    node.line = line();
    return node;
  }  
  
  Doctype parseDoctype() =>
    new Doctype(expect('doctype').val)
      ..line = line();

  Filter parseFilter(){
    var tok = expect('filter');
    var attrs = accept('attrs');

    lexer.pipeless = true;
    var block = parseTextBlock();
    lexer.pipeless = false;

    return new Filter(tok.val, block, attrs != null ? attrs.attrs : null)
      ..line = line();
  }
  
  Each parseEach(){
    var tok = expect('each');
    var node = new Each(tok.code, tok.val, tok.key)
      ..line = line()
      ..block = block();
    if (peek().type == 'code' && peek().val == 'else') {
      advance();
      node.alternative = block();
    }
    return node;
  }  

  String resolvePath(String path, purpose) {
    var dirname = _dirname;
    var basename = _basename;
    var join = _join;

    if (path[0] != '/' && filename == null)
      throw new ParseError('the "filename" option is required to use "$purpose" with "relative" paths');

    if (path[0] == '/' && options['basedir'] == null)
      throw new ParseError('the "basedir" option is required to use "$purpose" with "absolute" paths');

    path = join([path[0] == '/' ? options['basedir'] : dirname(filename), path]);

    if (basename(path).indexOf('.') == -1) path += '.jade';

    return path;
  }  
  
  Literal parseExtends(){
    var path = resolvePath(expect('extends').val.trim(), 'extends');
    if ('.jade' != path.substring(path.length-5)) path += '.jade';

    var str = new File(path).readAsStringSync();
    var parser = createParser(str, path, options);

    parser.blocks = blocks;
    parser.contexts = contexts;
    extending = parser;

    // TODO: null node
    return new Literal('');
  }
  
  Block parseBlock(){
    var _block = expect('block');
    var mode = _block.mode;
    var name = _block.val.trim();

    _block = 'indent' == peek().type
      ? block()
      : new Block(new Literal(''));

    Block prev = _or(blocks[name], () => new Block());
    if (prev.mode == 'replace') return blocks[name] = prev;

    var allNodes = prev.prepended
      ..addAll(_block.nodes)
      ..addAll(prev.appended);

    switch (mode) {
      case 'append':
        prev.appended = prev.parser == this ?
                        (prev.appended..addAll(_block.nodes)) :
                        (_block.nodes..addAll(prev.appended));
        break;
      case 'prepend':
        prev.prepended = prev.parser == this ?
                         (_block.nodes.addAll(prev.prepended)) :
                         (prev.prepended.addAll(_block.nodes));
        break;
    }
    _block
      ..nodes = allNodes
      ..appended = prev.appended
      ..prepended = prev.prepended
      ..mode = mode
      ..parser = this;

    return blocks[name] = _block;
  }
  
  Node parseInclude(){
    var path = resolvePath(expect('include').val.trim(), 'include');
    var extname = _extname;

    // non-jade
    var str = new File(path).readAsStringSync();
    if ('.jade' != path.substring(path.length - 5, path.length)) {
      str = str.replaceAll(new RegExp(r"\r"), '');
      var ext = extname(path).substring(1);
      if (filterExists(ext)) str = filter(ext, str, { "filename": path });
      return new Literal(str);
    }

    var parser = createParser(str, path, options);
    parser.blocks = merge({}, blocks);

    parser.mixins = mixins;

    context(parser);
    var ast = parser.parse();
    context();
    ast.filename = path;

    if ('indent' == peek().type) {
      ast.includeBlock().add(block());
    }

    return ast;
  }
  
  Mixin parseCall(){
    var tok = expect('call');
    var name = tok.val;
    var args = tok.args;
    var mixin = new Mixin(name, args, new Block(), true);

    tag(mixin);
    if (mixin.code != null) {
      mixin.block.add(mixin.code);
      mixin.code = null;
    }
    if (mixin.block.isEmpty) mixin.block = null;
    return mixin;
  }  
  
  Mixin parseMixin(){
    var tok = expect('mixin');
    var name = tok.val;
    var args = tok.args;
    var mixin;

    // definition
    if ('indent' == peek().type) {
      mixin = new Mixin(name, args, block(), false);
      mixins[name] = mixin;
      return mixin;
    // call
    } else {
      return new Mixin(name, args, null, true);
    }
  }
  
  Block parseTextBlock(){
    var block = new Block();
    block.line = line();
    var spaces = expect('indent').val;
    if (null == _spaces) _spaces = spaces;    
    var indent = new List.filled(spaces - _spaces + 1, '').join(' ');
    while ('outdent' != peek().type) {
      switch (peek().type) {
        case 'newline':
          advance();
          break;
        case 'indent':
          parseTextBlock().nodes.forEach((node){
            block.add(node);
          });
          break;
        default:
          var text = new Text(indent + advance().val);
          text.line = line();
          block.add(text);
      }
    }

    if (spaces == _spaces) _spaces = null;
    expect('outdent');
    return block;
  }
  
  Block block(){
    var block = new Block();
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
  
  parseInterpolation(){
    var tok = advance();
    return tag(new Tag(tok.val)
      ..buffer = true);
  }
 
  parseTag(){
    // ast-filter look-ahead
    var i = 2;
    if ('attrs' == lookahead(i).type) ++i;

    var _tok = advance();
    return tag(new Tag(_tok.val)
      ..selfClosing = _tok.selfClosing);
  }  
 
  tag(Tag tag){
    bool dot = false;

    tag.line = line();

    // (attrs | class | id)*
    out:
      while (true) {
        switch (peek().type) {
          case 'id':
          case 'class':
            var _tok = advance();
            tag.setAttribute(_tok.type, "'${_tok.val}'");
            continue;
          case 'attrs':
            var _tok = advance();
            Map obj = _tok.attrs;
            var escaped = _tok.escaped;
            var names = obj.keys;

            if (_tok.selfClosing) tag.selfClosing = true;

            for (var name in names) {
              var val = obj[name];
              tag.setAttribute(name, val, escaped[name]);
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
        tag.block.add(parseText());
        break;
      case 'code':
        tag.code = parseCode();
        break;
      case ':':
        advance();
        tag.block = new Block()
          ..add(parseExpr());
        break;
    }

    // newline*
    while ('newline' == peek().type) advance();

    tag.textOnly = tag.textOnly || textOnly.contains(tag.name);

    // script special-case
    if ('script' == tag.name) {
      var type = tag.getAttribute('type');
      if (!dot && type != null && 'text/javascript' != type.replaceAll(new RegExp("^['\"]|['\"]\$"), '')) {
        tag.textOnly = false;
      }
    }

    // block?
    if ('indent' == peek().type) {
      if (tag.textOnly) {
        if (!dot) {
          logWarn('$filename, line ${peek().line}:');
          logWarn('Implicit textOnly for `script` and `style` is deprecated.  Use `script.` or `style.` instead.');
        }
        lexer.pipeless = true;
        tag.block = parseTextBlock();
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

