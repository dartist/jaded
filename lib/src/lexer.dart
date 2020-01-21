//ignore_for_file: non_constant_identifier_names,missing_return,prefer_interpolation_to_compose_strings,lines_longer_than_80_chars
part of jaded;

var _parseJSExpression = parseMax;

class _Token {
  String type;
  int line;
  dynamic val;
  bool buffer;
  bool escape;
  Map escaped;
  bool selfClosing = false;
  String mode;
  String args;
  String key;
  String code;
  Map attrs;

  _Token([this.type, this.line, this.val]);
}

class _Lexer {
  String str;

  String input;
  bool colons;
  List<_Token> deferredTokens = []; //ignore: prefer_final_fields
  int lastIndents = 0;
  int lineno = 1;
  List stash = [];
  List<int> indentStack = [];
  RegExp indentRe;
  bool pipeless = false;
  List<String> varDeclarations = [];
  List<String> varReferences = [];

  void addVarDeclaration(String varName) {
    if (!varDeclarations.contains(varName)) varDeclarations.add(varName);
  }

  void addVarReference(String varExpr) {
    //Register the root var reference
    var pos = varExpr.indexOf('.');
    if (pos == -1) pos = varExpr.indexOf('[');
    if (pos == -1) pos = varExpr.length;

    var varName = varExpr.substring(0, pos);
    if (!varReferences.contains(varName)) varReferences.add(varName);
  }

  _Lexer(this.str, {this.colons = false}) {
    input = str.replaceAll(RegExp(r"\r\n|\r"), '\n');
  }

  _Token tok(String type, [dynamic val]) => _Token(type, lineno, val);

  String consume(int len) => input = input.substring(len);
  
  _Token scan(RegExp regexp, String type) {
    
    List<String> captures;
    if ((captures = exec(regexp, input)) != null) {
      consume(captures[0].length);
      return tok(type, captures.length > 1 ? captures[1] : null);
    }
  }

  void defer(_Token tok) => deferredTokens.add(tok);

  dynamic lookahead(int n) {
    var fetch = n - stash.length;
    while (fetch-- > 0) {
      stash.add(next());
    }
    return stash[--n];
  }

  SrcPosition bracketExpression([int skip = 0]) {
    var start = input[skip];
    if (start != '(' && start != '{' && start != '[') {
      throw ParseError('unrecognized start character');
    }
    var end = ({'(': ')', '{': '}', '[': ']'})[start];
    var range = _parseJSExpression(input, start: skip + 1);
    if (input[range.end] != end) {
      throw ParseError(
          '''start character $start does not match end character ${input[range.end]}''');
    }
    return range;
  }

  _Token stashed() => stash.length > 0 ? stash.removeAt(0) : null;

  _Token deferred() =>
      deferredTokens.length > 0 ? deferredTokens.removeAt(0) : null;

  _Token eos() {
    if (input.length > 0) return null;
    if (indentStack.length > 0) {
      indentStack.removeAt(0);
      return tok('outdent');
    } else {
      return tok('eos');
    }
  }
  
  _Token blank() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^\n *\n"), input)) != null) {
      consume(captures[0].length - 1);
      ++lineno;
      return pipeless ? tok('text', '') : next();
    }
  }
  
  _Token comment() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^ *\/\/(-)?([^\n]*)"), input)) != null) {
      consume(captures[0].length);
      return tok('comment', captures[2])..buffer = '-' != captures[1];
    }
  }
  
  _Token interpolation() {
    if (RegExp(r"^#\{").hasMatch(input)) {
      var match;
      try {
        match = bracketExpression(1);
      } on Exception {
        return null; 
        //not an interpolation expression, just an unmatched open interpolation
      }
      consume(match.end + 1);
      return tok('interpolation', match.src);
    }
  }
  
  _Token tag() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^(\w[-:\w]*)(\/?)"), input)) != null) {
      consume(captures[0].length);
      _Token _tok;
      var name = captures[1];
      if (':' == name[name.length - 1]) {
        name = name.substring(0, name.length - 1);
        _tok = tok('tag', name);
        defer(tok(':'));
        while (' ' == input[0]) {input = input.substring(1);}
      } else {
        _tok = tok('tag', name);
      }
      _tok.selfClosing = captures[2].isNotEmpty;
      return _tok;
    }
  }

  _Token filter() => scan(RegExp(r"^:(\w+)"), 'filter');

  _Token doctype() => scan(RegExp(r"^(?:!!!|doctype) *([^\n]+)?"), 'doctype');

  _Token id() => scan(RegExp(r"^#([\w-]+)"), 'id');

  _Token className() => scan(RegExp(r"^\.([\w-]+)"), 'class');

  _Token text() => scan(RegExp(r"^(?:\| ?| ?)?([^\n]+)"), 'text');
  
  _Token Extends() => scan(RegExp(r"^extends? +([^\n]+)"), 'extends');

  _Token prepend() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^prepend +([^\n]+)"), input)) != null) {
      consume(captures[0].length);
      var name = captures[1];
      return tok('block', name)..mode = 'prepend';
    }
  }

  _Token append() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^append +([^\n]+)"), input)) != null) {
      consume(captures[0].length);
      var name = captures[1];
      return tok('block', name)..mode = 'append';
    }
  }

  _Token block() {
    List<String> captures;
    if ((captures = exec(
            RegExp(r"^block\b *(?:(prepend|append) +)?([^\n]*)"), input)) !=
        null) {
      consume(captures[0].length);
      var mode = captures[1];
      if (mode == null || mode.isEmpty) mode = 'replace';
      var name = captures[2];

      return tok('block', name)..mode = mode;
    }
  }

  _Token yield() => scan(RegExp(r"^yield *"), 'yield');

  _Token include() => scan(RegExp(r"^include +([^\n]+)"), 'include');

  _Token Case() => scan(RegExp(r"^case +([^\n]+)"), 'case');

  _Token when() => scan(RegExp(r"^when +([^:\n]+)"), 'when');

  _Token Default() => scan(RegExp(r"^default *"), 'default');

  _Token assignment() {
    List<String> captures;
    //DB original: ^(\w+) += *([^;\n]+)( *;? *)
    if ((captures = exec(RegExp(r"^(\w+) += *([^\n]+)( *;? *)"), input)) !=
        null) {
      consume(captures[0].length);
      var name = captures[1];
      var val = captures[2];

      val = val.replaceFirst(RegExp(r"\s*;\s*$"), ''); //DB: remove trailing ';'

      addVarDeclaration(name);

      if (_isVarExpr(val)) addVarReference(val);

      return tok('code', '$name = ($val);');
    }
  }

  _Token call() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^\+([-\w]+)"), input)) != null) {
      consume(captures[0].length);
      var _tok = tok('call', captures[1]);

      // Check for args (not attributes)
      if ((captures = exec(RegExp(r"^ *\("), input)) != null) {
        try {
          var range = bracketExpression(captures[0].length - 1);
          if (!RegExp(r"^ *[-\w]+ *=").hasMatch(range.src)) {
            // not attributes
            consume(range.end + 1);
            _tok.args = range.src;
          }
        } on Exception {
          //not a bracket expcetion, just unmatched open parens
        }
      }

      return _tok;
    }
  }

  _Token mixin() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^mixin +([-\w]+)(?: *\((.*)\))?"), input)) !=
        null) {
      consume(captures[0].length);
      return tok('mixin', captures[1])..args = captures[2];
    }
    /*else if ((captures = exec(RegExp(r"^\+(\s*)(([-\w]+)|(#\{))"), input))!= null){
      consume(captures[0].length);
      return tok('mixin', captures[2])..args = captures[3];
    }*/
  }

  _Token conditional() {
    List<String> captures;
    if ((captures =
            exec(RegExp(r"^(if|unless|else if|else)\b([^\n]*)"), input)) !=
        null) {
      consume(captures[0].length);
      var type = captures[1];
      var js = captures[2];

      switch (type) {
        case 'if':
          js = 'if ($js)';
          break;
        case 'unless':
          js = 'if (!($js))';
          break;
        case 'else if':
          js = 'else if ($js)';
          break;
        case 'else':
          js = 'else';
          break;
      }

      return tok('code', js);
    }
  }

  _Token While() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^while +([^\n]+)"), input)) != null) {
      consume(captures[0].length);
      return tok('code', 'while (${captures[1]})');
    }
  }

  _Token each() {
    List<String> captures;
    if ((captures = exec(
            RegExp(
                r"^(?:- *)?(?:each|for) +([a-zA-Z_$][\w$]*)(?: *, *([a-zA-Z_$][\w$]*))? * in *([^\n]+)"),
            input)) !=
        null) {
      consume(captures[0].length);

      var code = captures[3];
      if (_isVarExpr(code)) addVarReference(code);

      return tok('each', captures[1])
        ..key =
            captures[2] == null || captures[2].isEmpty ? r'$index' : captures[2]
        ..code = code;
    }
  }

  _Token code() {
    List<String> captures;
    if ((captures = exec(RegExp(r"^(!?=|-)[ \t]*([^\n]+)"), input)) != null) {
      consume(captures[0].length);
      var flags = captures[1];
      var expr = captures[2];
      //DB: keep record of var references
      var varRegEx = RegExp(r"^[A-Za-z_]+");
      if (expr.startsWith("var ")) {
        expr = expr.substring("var ".length);
        var ret = exec(varRegEx, expr);
        if (ret != null) addVarDeclaration(ret[0]);
      } else if (flags == "=") {
        if (_isVarExpr(expr)) addVarReference(expr);
      }
      return tok('code', expr)
        ..escape = flags.substring(0, 1) == '='
        ..buffer = flags.substring(0, 1) == '=' ||
            (flags.length > 1 && flags.substring(1, 2) == '=');
    }
  }

  _Token attrs() {
    if ('(' == input.substring(0, 1)) {
      var index = bracketExpression().end;
      var str = input.substring(1, index);
      var _tok = tok('attrs');
      var len = str.length;
      var states = ['key'];
      var _colons = colons, escapedAttr, key = '', val = '', quote, c, p;

      state() => states[states.length - 1];

      interpolate(String attr) {
        return attr.replaceAllMapped(RegExp(r"(\\)?#\{(.+)"), (Match match) {
          //_, escape, expr
          var _ = match.group(0);
          var escape = match.group(1);
          var expr = match.group(2);

          if (escape != null) return _;
          try {
            var range = _parseJSExpression(expr);
            if (expr[range.end] != '}'){
              return _.substring(0, 2) + interpolate(_.substring(2));}
            return quote +
                " + (\"\${" +
                range.src +
                "}\") + " +
                quote +
                interpolate(expr.substring(range.end + 1));
          } on Exception {
            return _.substring(0, 2) + interpolate(_.substring(2));
          }
        });
      }

      consume(index + 1);
      _tok.attrs = {};
      _tok.escaped = {};

      parse(c) {
        var real = c;
        // TODO: remove when people fix ":"
        if (colons && ':' == c) c = '=';
        switch (c) {
          case ',':
          case '\n':
            switch (state()) {
              case 'expr':
              case 'array':
              case 'string':
              case 'object':
                val += c;
                break;
              default:
                states.add('key');
                val = val.trim();
                key = key.trim();
                if ('' == key) return;
                key = key
                    .replaceAll(RegExp("^['\"]|['\"]\$"), '')
                    .replaceFirst('!', '');
                _tok.escaped[key] = escapedAttr;
                _tok.attrs[key] = '' == val ? true : interpolate(val);
                key = val = '';
            }
            break;
          case '=':
            switch (state()) {
              case 'key char':
                key += real;
                break;
              case 'val':
              case 'expr':
              case 'array':
              case 'string':
              case 'object':
                val += real;
                break;
              default:
                escapedAttr = '!' != p;
                states.add('val');
            }
            break;
          case '(':
            if ('val' == state() || 'expr' == state()) states.add('expr');
            val += c;
            break;
          case ')':
            if ('expr' == state() || 'val' == state()) states.removeLast();
            val += c;
            break;
          case '{':
            if ('val' == state()) states.add('object');
            val += c;
            break;
          case '}':
            if ('object' == state()) states.removeLast();
            val += c;
            break;
          case '[':
            if ('val' == state()) states.add('array');
            val += c;
            break;
          case ']':
            if ('array' == state()) states.removeLast();
            val += c;
            break;
          case '"':
          case "'":
            switch (state()) {
              case 'key':
                states.add('key char');
                break;
              case 'key char':
                states.removeLast();
                break;
              case 'string':
                if (c == quote) states.removeLast();
                val += c;
                break;
              default:
                states.add('string');
                val += c;
                quote = c;
            }
            break;
          case '':
            break;
          default:
            switch (state()) {
              case 'key':
              case 'key char':
                key += c;
                break;
              default:
                val += c;
            }
        }
        p = c;
      }

      for (var i = 0; i < len; ++i) {
        parse(str.substring(i, i + 1));
      }

      parse(',');

      if (input.isNotEmpty && '/' == input.substring(0, 1)) {
        consume(1);
        _tok.selfClosing = true;
      }

      return _tok;
    }
  }

  _Token indent() {
    List<String> captures;
    RegExp re;

    // established regexp
    if (indentRe != null) {
      captures = exec(indentRe, input);
      // determine regexp
    } else {
      // tabs
      re = RegExp(r"^\n(\t*) *");
      captures = exec(re, input);

      // spaces
      if (captures != null && captures[1].length == 0) {
        re = RegExp(r"^\n( *)");
        captures = exec(re, input);
      }

      // established
      if (captures != null && captures[1].length > 0) indentRe = re;
    }

    if (captures != null) {
      var _tok;
      var indents = captures[1].length;

      ++lineno;
      consume(indents + 1);

      var firstChar = input.isNotEmpty ? input.substring(0, 1) : null;
      if (' ' == firstChar || '\t' == firstChar) {
        throw ParseError(
            'Invalid indentation, you can use tabs or spaces but not both');
      }

      // blank line
      if ('\n' == firstChar) return tok('newline');

      // outdent
      if (indentStack.length > 0 && indents < indentStack[0]) {
        while (indentStack.length > 0 && indentStack[0] > indents) {
          stash.add(tok('outdent'));
          indentStack.removeAt(0);
        }
        _tok = stash.removeLast();
        // indent
      } else if (indents > 0 &&
          indents != (indentStack.length > 0 ? indentStack[0] : null)) {
        indentStack.insert(0, indents);
        _tok = tok('indent', indents);
        // newline
      } else {
        _tok = tok('newline');
      }

      return _tok;
    }
  }

  _Token pipelessText() {
    if (pipeless) {
      if (input.startsWith('\n')) return null;
      var i = input.indexOf('\n');
      if (-1 == i) i = input.length;
      var str = input.substring(0, i);
      consume(str.length);
      return tok('text', str);
    }
  }

  _Token colon() => scan(RegExp(r"^: *"), ':');
  //ignore: unnecessary_lambdas
  _Token advance() => or(stashed(), ()=>next());

  _Token next() {
    var ret;
    if ((ret = deferred()) != null) return ret;
    if ((ret = blank()) != null) return ret;
    if ((ret = eos()) != null) return ret;
    if ((ret = pipelessText()) != null) return ret;
    if ((ret = yield()) != null) return ret;
    if ((ret = doctype()) != null) return ret;
    if ((ret = interpolation()) != null) return ret;
    if ((ret = Case()) != null) return ret;
    if ((ret = when()) != null) return ret;
    if ((ret = Default()) != null) return ret;
    if ((ret = Extends()) != null) return ret;
    if ((ret = append()) != null) return ret;
    if ((ret = prepend()) != null) return ret;
    if ((ret = block()) != null) return ret;
    if ((ret = include()) != null) return ret;
    if ((ret = mixin()) != null) return ret;
    if ((ret = call()) != null) return ret;
    if ((ret = conditional()) != null) return ret;
    if ((ret = each()) != null) return ret;
    if ((ret = While()) != null) return ret;
    if ((ret = assignment()) != null) return ret;
    if ((ret = tag()) != null) return ret;
    if ((ret = filter()) != null) return ret;
    if ((ret = code()) != null) return ret;
    if ((ret = id()) != null) return ret;
    if ((ret = className()) != null) return ret;
    if ((ret = attrs()) != null) return ret;
    if ((ret = indent()) != null) return ret;
    if ((ret = comment()) != null) return ret;
    if ((ret = colon()) != null) return ret;
    if ((ret = text()) != null) return ret;
    return null;
  }
}
