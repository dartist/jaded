part of jaded;

/// merge multiple Map objects into one Map
Map merge<k, v>(Map a, Map b) {
  if (a.runtimeType != b.runtimeType) {
    throw TypeError();
  }
  for (var key in b.keys) {
    if (a.containsKey(key)) {
      if (a[key] is List) {
        var temp = <v>[];
        a[key].forEach((el) {
          if (el != null) {
            temp.add(el);
          }
        });
        b[key] is List
            ? b[key].forEach((el) {
                if (el != null) {
                  temp.add(el);
                }
              })
            : b[key] != null ? temp.add(b[key]) : null;
        a[key] = temp;
      } else if (a[key] is Map && b[key] is Map) {
        merge(a[key], b[key]);
      } else {
        var temp = a[key];
        a[key] = <dynamic>[]..add(temp);
        b[key] is List ? a[key].addAll(b[key]) : a[key].add(b[key]);
      }
    } else {
      a[key] = b[key];
    }
  }
  return a;
}

bool _isVarExpr(String expr) {
  if (expr.isEmpty) return false;
  var firstChar = expr.substring(0, 1);
  var isVar = RegExp(r'^[A-Za-z0-9_]+\.?\[?').hasMatch(expr) &&
      !(firstChar.compareTo('0') >= 0 && firstChar.compareTo('9') < 0) &&
      !expr.contains('(');
  var isExpr = RegExp(r'true|false|null').hasMatch(expr);
  return isVar && !isExpr && !isKeyword(expr);
}
