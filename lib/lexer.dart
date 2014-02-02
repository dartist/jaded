part of jaded;

var parseJSExpression = parseMax;

class Token {
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

  Token([this.type, this.line, this.val]);
}

class Lexer {
  String str;

  String input;
  bool colons;
  List<Token> deferredTokens = [];
  int lastIndents = 0;
  int lineno = 1;
  List stash = [];
  List<int> indentStack = [];
  RegExp indentRe;
  bool pipeless = false;
  List<String> varDeclarations = [];
  List<String> varReferences = [];

  void addVarDeclaration(String varName){
    if (!varDeclarations.contains(varName))
      varDeclarations.add(varName);
  }

  void addVarReference(String varExpr){
    //Register the root var reference
    var pos = varExpr.indexOf('.');
    if (pos == -1) pos = varExpr.indexOf('[');
    if (pos == -1) pos = varExpr.length;

    var varName = varExpr.substring(0, pos);
    if (!varReferences.contains(varName))
      varReferences.add(varName);
  }

  Lexer(this.str, {this.colons:false}){
    input = str.replaceAll(new RegExp(r"\r\n|\r"), '\n');
  }

  Token tok(String type, [val]) => new Token(type, lineno, val);

  consume(int len) =>
    input = input.substring(len);

  Token scan(RegExp regexp, String type){
    List<String> captures;
    if ((captures = exec(regexp, input)) != null){
      consume(captures[0].length);
      return tok(type, captures.length > 1 ? captures[1] : null);
    }
  }

  defer(Token tok) =>
    deferredTokens.add(tok);

  lookahead(int n){
    var fetch = n - stash.length;
    while (fetch-- > 0) stash.add(next());
    return stash[--n];
  }

 SrcPosition bracketExpression([int skip=0]){
    var start = input[skip];
    if (start != '(' && start != '{' && start != '[') throw new ParseError('unrecognized start character');
    var end = ({'(': ')', '{': '}', '[': ']'})[start];
    var range = parseJSExpression(input, start: skip + 1);
    if (input[range.end] != end) throw new ParseError('start character ' + start + ' does not match end character ' + input[range.end]);
    return range;
  }

Token stashed() =>
  stash.length > 0 ? stash.removeAt(0) : null;

Token deferred() =>
  deferredTokens.length > 0 ? deferredTokens.removeAt(0) : null;

Token eos(){
  if (input.length > 0) return null;
  if (indentStack.length > 0) {
    indentStack.removeAt(0);
    return tok('outdent');
  } else {
    return tok('eos');
  }
}

blank(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^\n *\n"), input)) != null) {
    consume(captures[0].length - 1);
    ++lineno;
    return pipeless
        ? tok('text', '')
        : next();
  }
}

comment(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^ *\/\/(-)?([^\n]*)"), input)) != null) {
    consume(captures[0].length);
    return tok('comment', captures[2])
      ..buffer = '-' != captures[1];
  }
}

interpolation(){
  if (new RegExp(r"^#\{").hasMatch(input)){
    var match;
    try {
      match = bracketExpression(1);
    } catch (ex) {
      return null;//not an interpolation expression, just an unmatched open interpolation
    }
    consume(match.end + 1);
    return tok('interpolation', match.src);
  }
}

Token tag(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^(\w[-:\w]*)(\/?)"), input)) != null) {
    consume(captures[0].length);
    Token _tok;
    String name = captures[1];
    if (':' == name[name.length - 1]) {
      name = name.substring(0, name.length-1);
      _tok = tok('tag', name);
      defer(tok(':'));
      while (' ' == input[0]) input = input.substring(1);
    } else {
      _tok = tok('tag', name);
    }
    _tok.selfClosing = captures[2].isNotEmpty;
    return _tok;
  }
}

filter() => scan(new RegExp(r"^:(\w+)"), 'filter');

doctype() => scan(new RegExp(r"^(?:!!!|doctype) *([^\n]+)?"), 'doctype');

id() => scan(new RegExp(r"^#([\w-]+)"), 'id');

className() => scan(new RegExp(r"^\.([\w-]+)"), 'class');

text() =>
    scan(new RegExp(r"^(?:\| ?| ?)?([^\n]+)"), 'text');

Extends() => scan(new RegExp(r"^extends? +([^\n]+)"), 'extends');

prepend() {
  List<String> captures;
  if ((captures = exec(new RegExp(r"^prepend +([^\n]+)"), input)) != null) {
    consume(captures[0].length);
    var name = captures[1];
    return tok('block', name)
      ..mode = 'prepend';
  }
}

append(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^append +([^\n]+)"), input)) != null) {
    consume(captures[0].length);
    var name = captures[1];
    return tok('block', name)
      ..mode = 'append';
  }
}

block(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^block\b *(?:(prepend|append) +)?([^\n]*)"), input)) != null) {
    consume(captures[0].length);
    var mode = captures[1];
    if (mode == null || mode.isEmpty)
      mode = 'replace';
    var name = captures[2];

    return tok('block', name)
      ..mode = mode;
  }
}

yield() => scan(new RegExp(r"^yield *"), 'yield');

include() => scan(new RegExp(r"^include +([^\n]+)"), 'include');

Case() => scan(new RegExp(r"^case +([^\n]+)"), 'case');

when() => scan(new RegExp(r"^when +([^:\n]+)"), 'when');

Default() => scan(new RegExp(r"^default *"), 'default');

assignment() {
  List<String> captures;
  //DB original: ^(\w+) += *([^;\n]+)( *;? *)
  if ((captures = exec(new RegExp(r"^(\w+) += *([^\n]+)( *;? *)"), input)) != null) {

    consume(captures[0].length);
    var name = captures[1];
    var val = captures[2];

    val = val.replaceFirst(new RegExp(r"\s*;\s*$"), ''); //DB: remove trailing ';'

    addVarDeclaration(name);

    if (_isVarExpr(val))
      addVarReference(val);

    return tok('code', '$name = ($val);');
  }
}

call(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^\+([-\w]+)"), input)) != null) {
    consume(captures[0].length);
    var _tok = tok('call', captures[1]);

    // Check for args (not attributes)
    if ((captures = exec(new RegExp(r"^ *\("), input)) != null) {
      try {
        var range = bracketExpression(captures[0].length - 1);
        if (!new RegExp(r"^ *[-\w]+ *=").hasMatch(range.src)) { // not attributes
          consume(range.end + 1);
          _tok.args = range.src;
        }
      } catch (ex) {
        //not a bracket expcetion, just unmatched open parens
      }
    }

    return _tok;
  }
}

mixin(){
  List<String> captures;
  if ((captures = exec(new RegExp(r"^mixin +([-\w]+)(?: *\((.*)\))?"), input)) != null) {
    consume(captures[0].length);
    return tok('mixin', captures[1])
      ..args = captures[2];
  }
}

conditional() {
  List<String> captures;
  if ((captures = exec(new RegExp(r"^(if|unless|else if|else)\b([^\n]*)"), input)) != null) {
    consume(captures[0].length);
    var type = captures[1];
    var js = captures[2];

    switch (type) {
      case 'if': js = 'if ($js)'; break;
      case 'unless': js = 'if (!($js))'; break;
      case 'else if': js = 'else if ($js)'; break;
      case 'else': js = 'else'; break;
    }

    return tok('code', js);
  }
}

While() {
  List<String> captures;
  if ((captures = exec(new RegExp(r"^while +([^\n]+)"), input)) != null) {
    consume(captures[0].length);
    return tok('code', 'while (${captures[1]})');
  }
}

each() {
  List<String> captures;
  if ((captures = exec(new RegExp(r"^(?:- *)?(?:each|for) +([a-zA-Z_$][\w$]*)(?: *, *([a-zA-Z_$][\w$]*))? * in *([^\n]+)"), input)) != null) {
    consume(captures[0].length);

    var code = captures[3];
    if (_isVarExpr(code))
      addVarReference(code);

      return tok('each', captures[1])
      ..key = captures[2] == null || captures[2].isEmpty ? r'$index' : captures[2]
      ..code = code;
  }
}

code() {
  List<String> captures;
  if ((captures = exec(new RegExp(r"^(!?=|-)[ \t]*([^\n]+)"), input)) != null) {
    consume(captures[0].length);
    var flags = captures[1];
    var expr = captures[2];
    //DB: keep record of var references
    var varRegEx = new RegExp(r"^[A-Za-z_]+");
    if (expr.startsWith("var ")){
      expr = expr.substring("var ".length);
      var ret = exec(varRegEx, expr);
      if (ret != null)
        addVarDeclaration(ret[0]);
    } else if (flags == "="){
      if (_isVarExpr(expr))
        addVarReference(expr);
    }
    return tok('code', expr)
      ..escape = flags.substring(0,1) == '='
      ..buffer = flags.substring(0,1) == '=' || (flags.length > 1 && flags.substring(1,2) == '=');
  }
}

attrs() {
    if ('(' == input.substring(0,1)) {
      int index = bracketExpression().end;
      String str = input.substring(1, index);
      Token _tok = tok('attrs');
      int len = str.length;
      List states = ['key'];
      var _colons = colons
        , escapedAttr
        , key = ''
        , val = ''
        , quote
        , c
        , p;

      state() => states[states.length - 1];

      interpolate(String attr) {
        return attr.replaceAllMapped(new RegExp(r"(\\)?#\{(.+)"), (Match match){
          //_, escape, expr
          String _ = match.group(0);
          String escape = match.group(1);
          String expr = match.group(2);

          if (escape != null) return _;
          try {
            var range = parseJSExpression(expr);
            if (expr[range.end] != '}') return _.substring(0, 2) + interpolate(_.substring(2));
            return quote + " + (\"\${" + range.src + "}\") + " + quote + interpolate(expr.substring(range.end + 1));
          } catch (ex) {
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
                key = key.replaceAll(new RegExp("^['\"]|['\"]\$"), '').replaceFirst('!', '');
                _tok.escaped[key] = escapedAttr;
                _tok.attrs[key] = '' == val
                  ? true
                  : interpolate(val);
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
            if ('val' == state()
              || 'expr' == state()) states.add('expr');
            val += c;
            break;
          case ')':
            if ('expr' == state()
              || 'val' == state()) states.removeLast();
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
        parse(str.substring(i,i+1));
      }

      parse(',');

      if (input.isNotEmpty && '/' == input.substring(0,1)) {
        consume(1);
        _tok.selfClosing = true;
      }

      return _tok;
    }
  }

indent(){
  List<String> captures;
  RegExp re;

  // established regexp
  if (indentRe != null) {
    captures = exec(indentRe, input);
  // determine regexp
  } else {
    // tabs
    re = new RegExp(r"^\n(\t*) *");
    captures = exec(re, input);

    // spaces
    if (captures != null && captures[1].length == 0) {
      re = new RegExp(r"^\n( *)");
      captures = exec(re, input);
    }

    // established
    if (captures != null && captures[1].length > 0) indentRe = re;
  }

  if (captures != null) {
    var _tok;
    int indents = captures[1].length;

    ++lineno;
    consume(indents + 1);

    var firstChar = input.isNotEmpty ? input.substring(0, 1) : null;
    if (' ' == firstChar || '\t' == firstChar) {
      throw new ParseError('Invalid indentation, you can use tabs or spaces but not both');
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
    } else if (indents > 0 && indents != (indentStack.length > 0 ? indentStack[0] : null)) {
      indentStack.insert(0, indents);
      _tok = tok('indent', indents);
    // newline
    } else {
      _tok = tok('newline');
    }

    return _tok;
  }
}

pipelessText() {
  if (pipeless) {
    if (input.startsWith('\n')) return null;
    var i = input.indexOf('\n');
    if (-1 == i) i = input.length;
    var str = input.substring(0, i);
    consume(str.length);
    return tok('text', str);
  }
}

Token colon() =>
    scan(new RegExp(r"^: *"), ':');

Token advance() => or(stashed(), () => next());

Token next(){
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