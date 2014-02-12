import "package:unittest/unittest.dart";
import "package:jaded/jaded.dart";

main(){
  group('merge(a, b, escaped) should merge classes into strings', (){
    var i=1;
    test('${i++}', () =>
      expect(merge({ 'foo': 'bar' }, { 'bar': 'baz' }),
          equals({ 'foo': 'bar', 'bar': 'baz' })));
    test('${i++}', () =>
      expect(merge({ 'class': [] }, {}),
        equals({ 'class': [] })));
    test('${i++}', () =>
      expect(merge({ 'class': [] }, { 'class': [] }),
        equals({ 'class': [] })));
    test('${i++}', () =>
      expect(merge({ 'class': [] }, { 'class': ['foo'] }),
        equals({ 'class': ['foo'] })));
    test('${i++}', () =>
      expect(merge({ 'class': ['foo'] }, {}),
        equals({ 'class': ['foo'] })));
    // 6
    test('${i++}', () =>
      expect(merge({ 'class': ['foo'] }, { 'class': ['bar'] }),
        equals({ 'class': ['foo','bar'] })));
    test('${i++}', () =>
      expect(merge({ 'class': ['foo', 'raz'] }, { 'class': ['bar', 'baz'] }),
        equals({ 'class': ['foo', 'raz', 'bar', 'baz'] })));
    test('${i++}', () =>
      expect(merge({ 'class': 'foo' }, { 'class': 'bar' }),
        equals({ 'class': ['foo', 'bar'] })));
    test('${i++}', () =>
      expect(merge({ 'class': 'foo' }, { 'class': ['bar', 'baz'] }),
        equals({ 'class': ['foo', 'bar', 'baz'] })));
    test('${i++}', () =>
      expect(merge({ 'class': ['foo', 'bar'] }, { 'class': 'baz' }),
        equals({ 'class': ['foo', 'bar', 'baz'] })));
    // 11
    test('${i++}', () =>
      expect(merge({ 'class': ['foo', null, 'bar'] }, { 'class': [null, 0, 'baz'] }),
        equals({ 'class': ['foo', 'bar', 0, 'baz'] })));
  });
}