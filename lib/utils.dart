part of jaded;

merge(Map a, Map b) {
  for (var key in b.keys) a[key] = b[key];
  return a;
}

_isVarExpr(String expr) {
  if (expr.isEmpty) return false;
  var firstChar = expr.substring(0, 1);
  var isVar = new RegExp(r"^[A-Za-z0-9_]+\.?\[?").hasMatch(expr)
    && !(firstChar.compareTo('0') >= 0 && firstChar.compareTo('9') < 0)
    && !expr.contains('(');
  var isExpr = new RegExp(r"true|false|null").hasMatch(expr);
  return isVar && !isExpr && !isKeyword(expr);
}
