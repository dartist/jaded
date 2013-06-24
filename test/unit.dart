import "package:unittest/unittest.dart";
import "../lib/jaded.dart";

main(){
  group('merge(a, b, escaped)', (){
    test('should merge classes into strings', (){
      expect(merge({ 'foo': 'bar' }, { 'bar': 'baz' }), 
          equals({ 'foo': 'bar', 'bar': 'baz' }));

      expect(merge({ 'class': [] }, {}),
        equals({ 'class': [] }));
  
      expect(merge({ 'class': [] }, { 'class': [] }),
        equals({ 'class': [] }));
  
      expect(merge({ 'class': [] }, { 'class': ['foo'] }),
        equals({ 'class': ['foo'] }));
  
      expect(merge({ 'class': ['foo'] }, {}),
        equals({ 'class': ['foo'] }));
  
      expect(merge({ 'class': ['foo'] }, { 'class': ['bar'] }),
        equals({ 'class': ['foo','bar'] }));
  
      expect(merge({ 'class': ['foo', 'raz'] }, { 'class': ['bar', 'baz'] }),
        equals({ 'class': ['foo', 'raz', 'bar', 'baz'] }));
  
      expect(merge({ 'class': 'foo' }, { 'class': 'bar' }),
        equals({ 'class': ['foo', 'bar'] }));
  
      expect(merge({ 'class': 'foo' }, { 'class': ['bar', 'baz'] }),
        equals({ 'class': ['foo', 'bar', 'baz'] }));
  
      expect(merge({ 'class': ['foo', 'bar'] }, { 'class': 'baz' }),
        equals({ 'class': ['foo', 'bar', 'baz'] }));
  
      expect(merge({ 'class': ['foo', null, 'bar'] }, { 'class': [null, 0, 'baz'] }),
        equals({ 'class': ['foo', 'bar', 0, 'baz'] }));
    });
  });
}