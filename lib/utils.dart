part of jaded;

merge(Map a, Map b) {
  for (var key in b.keys) a[key] = b[key];
  return a;
}

//polyfill for js /regex/.exec() to ease porting
List<String> exec(RegExp regex, String str){
  var m = regex.firstMatch(str);
  return m != null ? m.groups(new List.generate(m.groupCount + 1, (x) => x)) : null;
}
    
_isVar(String expr) {
  var isVar = new RegExp(r"^[A-Za-z_]+$").hasMatch(expr);
  var isExpr = new RegExp(r"true|false|null").hasMatch(expr);
  return isVar && !isExpr && !isKeyword(expr);
}

_or(value, defaultFn()) =>
    value != null ? value : defaultFn(); 

String _trimLeft(String str) => str.replaceFirst(new RegExp(r"^\s+"),"");

String _trimStart(String str, String start) {
  if (str.startsWith(start) && str.length > start.length) {
    return str.substring(start.length);
  }
  return str;
}

String _join(List paths){
  var sb = new StringBuffer();
  bool endsWithSlash = false;
  for (var oPath in paths){
    if (oPath == null) continue;
    String path = oPath.toString();
    if (path.isEmpty) continue;
    
    if (sb.length > 0 && !endsWithSlash)
      sb.write('/');
    
    String sanitizedPath = _trimStart(path.replaceAll("\\", "/"), "/");
    sb.write(sanitizedPath);
    endsWithSlash = sanitizedPath.endsWith("/");
  }
  return sb.toString();
}

String _dirname(String path){
  if (path == null || path.isEmpty) return null;
  var pos = path.lastIndexOf('/');
  return path.substring(0, pos);
}

String _basename(String path, [String trimExt]){
  if (path == null || path.isEmpty) return null;
  var pos = path.lastIndexOf('/');
  var basename = path.substring(pos + 1);
  return trimExt != null && basename.endsWith(trimExt)
    ? basename.substring(0, basename.length - trimExt.length)
    : basename;   
}

String _extname(String path){
  var extPos = path.lastIndexOf('.');
  if (extPos == -1) return '';
  return path.substring(extPos);
}
