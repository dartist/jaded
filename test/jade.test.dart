import "package:unittest/unittest.dart";
import "../lib/jaded.dart";

main(){
  
  renderEquals(String expected, String jade, [Map options, String reason]){    
    var fn = compile(jade, options);    
    return fn.then(expectAsync1((html){
//      print(html);
      expect(html, equals(expected), reason:reason);
    }));
  }
  
  //ignore passing tests
  ignore(a, fn){}
  
  group('jade', (){

    group('.compile()', (){
      ignore('should support doctypes', (){
        renderEquals('<?xml version="1.0" encoding="utf-8" ?>', '!!! xml');
        renderEquals('<!DOCTYPE html>', 'doctype html');
        renderEquals('<!DOCTYPE foo bar baz>', 'doctype foo bar baz');
        renderEquals('<!DOCTYPE html>', '!!! 5');
        renderEquals('<!DOCTYPE html>', '!!!', { 'doctype':'html' });
        renderEquals('<!DOCTYPE html>', '!!! html', { 'doctype':'xml' });
        renderEquals('<html></html>', 'html');
        renderEquals('<!DOCTYPE html><html></html>', 'html', { 'doctype':'html' });
        renderEquals('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN>', 'doctype html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN');
      });

//      test('should support Buffers', (){
//        renderEquals('<p>foo</p>', new Buffer('p foo'));
//      });

      ignore('should support line endings', (){
        var str, html;
        
        str = [
               'p',
               'div',
               'img'
               ].join('\r\n');

        html = [
                '<p></p>',
                '<div></div>',
                '<img/>'
                ].join('');
        
        renderEquals(html, str);

        str = [
               'p',
               'div',
               'img'
               ].join('\r');

        html = [
                '<p></p>',
                '<div></div>',
                '<img/>'
                ].join('');

        renderEquals(html, str);

        str = [
               'p',
               'div',
               'img'
               ].join('\r\n');

        html = [
                '<p></p>',
                '<div></div>',
                '<img>'
                ].join('');

        renderEquals(html, str, { 'doctype':'html' });
      });

      ignore('should support single quotes', (){
        renderEquals("<p>'foo'</p>", "p 'foo'");
        renderEquals("<p>'foo'</p>", "p\n  | 'foo'");
        renderEquals('<a href="/foo"></a>', "- var path = 'foo';\na(href='/' + path)");
      });

      ignore('should support block-expansion', (){
        renderEquals("<li><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", "li: a foo\nli: a bar\nli: a baz");
        renderEquals("<li class=\"first\"><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", "li.first: a foo\nli: a bar\nli: a baz");
        renderEquals('<div class="foo"><div class="bar">baz</div></div>', ".foo: .bar baz");
      });

      ignore('should support tags', (){
        var str = [
                   'p',
                   'div',
                   'img'
                   ].join('\n');

        var html = [
                    '<p></p>',
                    '<div></div>',
                    '<img/>'
                    ].join('');

        renderEquals(html, str, null, 'Test basic tags');
        renderEquals('<fb:foo-bar></fb:foo-bar>', 'fb:foo-bar', null, 'Test hyphens');
        renderEquals('<div class="something"></div>', 'div.something', null, 'Test classes');
        renderEquals('<div id="something"></div>', 'div#something', null, 'Test ids');
        renderEquals('<div class="something"></div>', '.something', null, 'Test stand-alone classes');
        renderEquals('<div id="something"></div>', '#something', null, 'Test stand-alone ids');
        renderEquals('<div id="foo" class="bar"></div>', '#foo.bar');
        renderEquals('<div id="foo" class="bar"></div>', '.bar#foo');
        renderEquals('<div id="foo" class="bar"></div>', 'div#foo(class="bar")');
        renderEquals('<div id="foo" class="bar"></div>', 'div(class="bar")#foo');
        renderEquals('<div id="bar" class="foo"></div>', 'div(id="bar").foo');
        renderEquals('<div class="foo bar baz"></div>', 'div.foo.bar.baz');
        renderEquals('<div class="foo bar baz"></div>', 'div(class="foo").bar.baz');
        renderEquals('<div class="foo bar baz"></div>', 'div.foo(class="bar").baz');
        renderEquals('<div class="foo bar baz"></div>', 'div.foo.bar(class="baz")');
        renderEquals('<div class="a-b2"></div>', 'div.a-b2');
        renderEquals('<div class="a_b2"></div>', 'div.a_b2');
        renderEquals('<fb:user></fb:user>', 'fb:user');
        renderEquals('<fb:user:role></fb:user:role>', 'fb:user:role');
        renderEquals('<colgroup><col class="test"/></colgroup>', 'colgroup\n  col.test');
      });

      ignore('should support nested tags', (){
        String str, html;
        str = [
               'ul',
               '  li a',
               '  li b',
               '  li',
               '    ul',
               '      li c',
               '      li d',
               '  li e',
               ].join('\n');

        html = [
                '<ul>',
                '<li>a</li>',
                '<li>b</li>',
                '<li><ul><li>c</li><li>d</li></ul></li>',
                '<li>e</li>',
                '</ul>'
                ].join('');

        renderEquals(html, str);

        str = [
               'a(href="#")',
               '  | foo ',
               '  | bar ',
               '  | baz'
               ].join('\n');

        renderEquals('<a href="#">foo \nbar \nbaz</a>', str);

        str = [
               'ul',
               '  li one',
               '  ul',
               '    | two',
               '    li three'
               ].join('\n');

        html = [
                '<ul>',
                '<li>one</li>',
                '<ul>two',
                '<li>three</li>',
                '</ul>',
                '</ul>'
                ].join('');

        renderEquals(html, str);
      });

      ignore('should support variable length newlines', (){
        var str = [
                   'ul',
                   '  li a',
                   '  ',
                   '  li b',
                   ' ',
                   '         ',
                   '  li',
                   '    ul',
                   '      li c',
                   '',
                   '      li d',
                   '  li e',
                   ].join('\n');

        var html = [
                    '<ul>',
                    '<li>a</li>',
                    '<li>b</li>',
                    '<li><ul><li>c</li><li>d</li></ul></li>',
                    '<li>e</li>',
                    '</ul>'
                    ].join('');

        renderEquals(html, str);
      });

      ignore('should support tab conversion', (){
        var str = [
                   'ul',
                   '\tli a',
                   '\t',
                   '\tli b',
                   '\t\t',
                   '\t\t\t\t\t\t',
                   '\tli',
                   '\t\tul',
                   '\t\t\tli c',
                   '',
                   '\t\t\tli d',
                   '\tli e',
                   ].join('\n');

        var html = [
                    '<ul>',
                    '<li>a</li>',
                    '<li>b</li>',
                    '<li><ul><li>c</li><li>d</li></ul></li>',
                    '<li>e</li>',
                    '</ul>'
                    ].join('');

        renderEquals(html, str);
      });

      ignore('should support newlines', (){
        String str, html;
        str = [
               'ul',
               '  li a',
               '  ',
               '    ',
               '',
               ' ',
               '  li b',
               '  li',
               '    ',
               '        ',
               ' ',
               '    ul',
               '      ',
               '      li c',
               '      li d',
               '  li e',
               ].join('\n');

        html = [
                '<ul>',
                '<li>a</li>',
                '<li>b</li>',
                '<li><ul><li>c</li><li>d</li></ul></li>',
                '<li>e</li>',
                '</ul>'
                ].join('');

        renderEquals(html, str);

        str = [
               'html',
               ' ',
               '  head',
               '    != "test"',
               '  ',
               '  ',
               '  ',
               '  body'
               ].join('\n');

        html = [
                '<html>',
                '<head>',
                'test',
                '</head>',
                '<body></body>',
                '</html>'
                ].join('');

        renderEquals(html, str);
        renderEquals('<foo></foo>something<bar></bar>', 'foo\n= "something"\nbar');
        renderEquals('<foo></foo>something<bar></bar>else', 'foo\n= "something"\nbar\n= "else"');
      });

      ignore('should support text', (){
        renderEquals('foo\nbar\nbaz', '| foo\n| bar\n| baz');
        renderEquals('foo \nbar \nbaz', '| foo \n| bar \n| baz');
        renderEquals('(hey)', '| (hey)');
        renderEquals('some random text', '| some random text');
        renderEquals('  foo', '|   foo');
        renderEquals('  foo  ', '|   foo  ');
        renderEquals('  foo  \n bar    ', '|   foo  \n|  bar    ');
      });

      ignore('should support pipe-less text', (){
        renderEquals('<pre><code><foo></foo><bar></bar></code></pre>', 'pre\n  code\n    foo\n\n    bar');
        renderEquals('<p>foo\n\nbar</p>', 'p.\n  foo\n\n  bar');
        renderEquals('<p>foo\n\n\n\nbar</p>', 'p.\n  foo\n\n\n\n  bar');
        renderEquals('<p>foo\n  bar\nfoo</p>', 'p.\n  foo\n    bar\n  foo');
        renderEquals('<script>s.parentNode.insertBefore(g,s)</script>', 'script.\n  s.parentNode.insertBefore(g,s)\n');
        renderEquals('<script>s.parentNode.insertBefore(g,s)</script>', 'script.\n  s.parentNode.insertBefore(g,s)');
      });

      ignore('should support tag text', (){
        renderEquals('<p>some random text</p>', 'p some random text');
        renderEquals('<p>click<a>Google</a>.</p>', 'p\n  | click\n  a Google\n  | .');
        renderEquals('<p>(parens)</p>', 'p (parens)');
        renderEquals('<p foo="bar">(parens)</p>', 'p(foo="bar") (parens)');
        renderEquals('<option value="">-- (optional) foo --</option>', 'option(value="") -- (optional) foo --');
      });

      ignore('should support tag text block', (){
        renderEquals('<p>foo \nbar \nbaz</p>', 'p\n  | foo \n  | bar \n  | baz');
        renderEquals('<label>Password:<input/></label>', 'label\n  | Password:\n  input');
        renderEquals('<label>Password:<input/></label>', 'label Password:\n  input');
      });

      test('should support tag text interpolation', (){
        renderEquals('yo, jade is cool', '| yo, #{name} is cool\n', { 'name': 'jade' });
//        renderEquals('<p>yo, jade is cool</p>', 'p yo, #{name} is cool', { 'name': 'jade' });
//        renderEquals('yo, jade is cool', '| yo, #{name || "jade"} is cool', { 'name': null });
//        renderEquals('yo, \'jade\' is cool', '| yo, #{name || "\'jade\'"} is cool', { 'name': null });
//        renderEquals('foo &lt;script&gt; bar', '| foo #{code} bar', { 'code': '<script>' });
//        renderEquals('foo <script> bar', '| foo !{code} bar', { 'code': '<script>' });
      });

//      test('should support flexible indentation', (){
//        renderEquals('<html><body><h1>Wahoo</h1><p>test</p></body></html>', 'html\n  body\n   h1 Wahoo\n   p test');
//      });
//
//      test('should support interpolation values', (){
//        renderEquals('<p>Users: 15</p>', 'p Users: #{15}');
//        renderEquals('<p>Users: </p>', 'p Users: #{null}');
//        renderEquals('<p>Users: </p>', 'p Users: #{undefined}');
//        renderEquals('<p>Users: none</p>', 'p Users: #{undefined || "none"}');
//        renderEquals('<p>Users: 0</p>', 'p Users: #{0}');
//        renderEquals('<p>Users: false</p>', 'p Users: #{false}');
//      });
//
//      test('should support test html 5 mode', (){
//        renderEquals('<!DOCTYPE html><input type="checkbox" checked>', '!!! 5\ninput(type="checkbox", checked)');
//        renderEquals('<!DOCTYPE html><input type="checkbox" checked>', '!!! 5\ninput(type="checkbox", checked=true)');
//        renderEquals('<!DOCTYPE html><input type="checkbox">', '!!! 5\ninput(type="checkbox", checked= false)');
//      });
//
//      test('should support multi-line attrs', (){
//        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\n  bar="baz"\n  checked) foo');
//        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\nbar="baz"\nchecked) foo');
//        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\n,bar="baz"\n,checked) foo');
//        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar",\nbar="baz",\nchecked) foo');
//      });
//
//      test('should support attrs', (){
//        renderEquals('<img src="&lt;script&gt;"/>', 'img(src="<script>")'), 'Test attr escaping');
//
//        renderEquals('<a data-attr="bar"></a>', 'a(data-attr="bar")');
//        renderEquals('<a data-attr="bar" data-attr-2="baz"></a>', 'a(data-attr="bar", data-attr-2="baz")');
//
//        renderEquals('<a title="foo,bar"></a>', 'a(title= "foo,bar")');
//        renderEquals('<a title="foo,bar" href="#"></a>', 'a(title= "foo,bar", href="#")');
//
//        renderEquals('<p class="foo"></p>', "p(class='foo')"), 'Test single quoted attrs');
//        renderEquals('<input type="checkbox" checked="checked"/>', 'input( type="checkbox", checked )');
//        renderEquals('<input type="checkbox" checked="checked"/>', 'input( type="checkbox", checked = true )');
//        renderEquals('<input type="checkbox"/>', 'input(type="checkbox", checked= false)');
//        renderEquals('<input type="checkbox"/>', 'input(type="checkbox", checked= null)');
//        renderEquals('<input type="checkbox"/>', 'input(type="checkbox", checked= undefined)');
//
//        renderEquals('<img src="/foo.png"/>', 'img(src="/foo.png")'), 'Test attr =');
//        renderEquals('<img src="/foo.png"/>', 'img(src  =  "/foo.png")'), 'Test attr = whitespace');
//        renderEquals('<img src="/foo.png"/>', 'img(src="/foo.png")'), 'Test attr :');
//        renderEquals('<img src="/foo.png"/>', 'img(src  =  "/foo.png")'), 'Test attr : whitespace');
//
//        renderEquals('<img src="/foo.png" alt="just some foo"/>', 'img(src="/foo.png", alt="just some foo")');
//        renderEquals('<img src="/foo.png" alt="just some foo"/>', 'img(src = "/foo.png", alt = "just some foo")');
//
//        renderEquals('<p class="foo,bar,baz"></p>', 'p(class="foo,bar,baz")');
//        renderEquals('<a href="http://google.com" title="Some : weird = title"></a>', 'a(href= "http://google.com", title= "Some : weird = title")');
//        renderEquals('<label for="name"></label>', 'label(for="name")');
//        renderEquals('<meta name="viewport" content="width=device-width"/>', "meta(name= 'viewport', content='width=device-width')"), 'Test attrs that contain attr separators');
//        renderEquals('<div style="color= white"></div>', "div(style='color= white')");
//        renderEquals('<div style="color: white"></div>', "div(style='color: white')");
//        renderEquals('<p class="foo"></p>', "p('class'='foo')"), 'Test keys with single quotes');
//        renderEquals('<p class="foo"></p>', "p(\"class\"= 'foo')"), 'Test keys with double quotes');
//
//        renderEquals('<p data-lang="en"></p>', 'p(data-lang = "en")');
//        renderEquals('<p data-dynamic="true"></p>', 'p("data-dynamic"= "true")');
//        renderEquals('<p data-dynamic="true" class="name"></p>', 'p("class"= "name", "data-dynamic"= "true")');
//        renderEquals('<p data-dynamic="true"></p>', 'p(\'data-dynamic\'= "true")');
//        renderEquals('<p data-dynamic="true" class="name"></p>', 'p(\'class\'= "name", \'data-dynamic\'= "true")');
//        renderEquals('<p data-dynamic="true" yay="yay" class="name"></p>', 'p(\'class\'= "name", \'data-dynamic\'= "true", yay)');
//
//        renderEquals('<input checked="checked" type="checkbox"/>', 'input(checked, type="checkbox")');
//
//        renderEquals('<a data-foo="{ foo: \'bar\', bar= \'baz\' }"></a>', 'a(data-foo  = "{ foo: \'bar\', bar= \'baz\' }")');
//
//        renderEquals('<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>', 'meta(http-equiv="X-UA-Compatible", content="IE=edge,chrome=1")');
//
//        renderEquals('<div style="background: url(/images/test.png)">Foo</div>', "div(style= 'background: url(/images/test.png)') Foo");
//        renderEquals('<div style="background = url(/images/test.png)">Foo</div>', "div(style= 'background = url(/images/test.png)') Foo");
//        renderEquals('<div style="foo">Foo</div>', "div(style= ['foo', 'bar'][0]) Foo");
//        renderEquals('<div style="bar">Foo</div>', "div(style= { foo: 'bar', baz: 'raz' }['foo']) Foo");
//        renderEquals('<a href="def">Foo</a>', "a(href='abcdefg'.substr(3,3)) Foo");
//        renderEquals('<a href="def">Foo</a>', "a(href={test: 'abcdefg'}.test.substr(3,3)) Foo");
//        renderEquals('<a href="def">Foo</a>', "a(href={test: 'abcdefg'}.test.substr(3,[0,3][1])) Foo");
//
//        renderEquals('<rss xmlns:atom="atom"></rss>', "rss(xmlns:atom=\"atom\")");
//        renderEquals('<rss xmlns:atom="atom"></rss>', "rss('xmlns:atom'=\"atom\")");
//        renderEquals('<rss xmlns:atom="atom"></rss>', "rss(\"xmlns:atom\"='atom')");
//        renderEquals('<rss xmlns:atom="atom" foo="bar"></rss>', "rss('xmlns:atom'=\"atom\", 'foo'= 'bar')");
//        renderEquals('<a data-obj="{ foo: \'bar\' }"></a>', "a(data-obj= \"{ foo: 'bar' }\")");
//
//        renderEquals('<meta content="what\'s up? \'weee\'"/>', 'meta(content="what\'s up? \'weee\'")');
//      });
//
//      test('should support colons option', (){
//        renderEquals('<a href="/bar"></a>', 'a(href:"/bar")', { colons: true });
//      });
//
//      test('should support class attr array', (){
//        renderEquals('<body class="foo bar baz"></body>', 'body(class=["foo", "bar", "baz"])');
//      });
//
//      test('should support attr interpolation', (){
//        // Test single quote interpolation
//        renderEquals('<a href="/user/12">tj</a>'
//            , "a(href='/user/#{id}') #{name}", { 'name': 'tj', id: 12 });
//
//        renderEquals('<a href="/user/12-tj">tj</a>'
//            , "a(href='/user/#{id}-#{name}') #{name}", { 'name': 'tj', id: 12 });
//
//        renderEquals('<a href="/user/&lt;script&gt;">tj</a>'
//            , "a(href='/user/#{id}') #{name}", { 'name': 'tj', id: '<script>' });
//
//        // Test double quote interpolation
//        renderEquals('<a href="/user/13">ds</a>'
//            , 'a(href="/user/#{id}") #{name}', { 'name': 'ds', id: 13 });
//
//        renderEquals('<a href="/user/13-ds">ds</a>'
//            , 'a(href="/user/#{id}-#{name}") #{name}', { 'name': 'ds', id: 13 });
//
//        renderEquals('<a href="/user/&lt;script&gt;">ds</a>'
//            , 'a(href="/user/#{id}") #{name}', { 'name': 'ds', id: '<script>' });
//      });
//
//      test('should support attr parens', (){
//        renderEquals('<p foo="bar">baz</p>', 'p(foo=((("bar"))))= ((("baz")))');
//      });
//
//      test('should support code attrs', (){
//        renderEquals('<p></p>', 'p(id= name)', { 'name': undefined });
//        renderEquals('<p></p>', 'p(id= name)', { 'name': null });
//        renderEquals('<p></p>', 'p(id= name)', { 'name': false });
//        renderEquals('<p id=""></p>', 'p(id= name)', { 'name': '' });
//        renderEquals('<p id="tj"></p>', 'p(id= name)', { 'name': 'tj' });
//        renderEquals('<p id="default"></p>', 'p(id= name || "default")', { 'name': null });
//        renderEquals('<p id="something"></p>', "p(id= 'something')", { 'name': null });
//        renderEquals('<p id="something"></p>', "p(id = 'something')", { 'name': null });
//        renderEquals('<p id="foo"></p>', "p(id= (true ? 'foo' : 'bar'))");
//        renderEquals('<option value="">Foo</option>', "option(value='') Foo");
//      });
//
//      test('should support code attrs class', (){
//        renderEquals('<p class="tj"></p>', 'p(class= name)', { 'name': 'tj' });
//        renderEquals('<p class="tj"></p>', 'p( class= name )', { 'name': 'tj' });
//        renderEquals('<p class="default"></p>', 'p(class= name || "default")', { 'name': null });
//        renderEquals('<p class="foo default"></p>', 'p.foo(class= name || "default")', { 'name': null });
//        renderEquals('<p class="default foo"></p>', 'p(class= name || "default").foo', { 'name': null });
//        renderEquals('<p id="default"></p>', 'p(id = name || "default")', { 'name': null });
//        renderEquals('<p id="user-1"></p>', 'p(id = "user-" + 1)');
//        renderEquals('<p class="user-1"></p>', 'p(class = "user-" + 1)');
//      });
//
//      test('should support code buffering', (){
//        renderEquals('<p></p>', 'p= null');
//        renderEquals('<p></p>', 'p= undefined');
//        renderEquals('<p>0</p>', 'p= 0');
//        renderEquals('<p>false</p>', 'p= false');
//      });
//
//      test('should support script text', (){
//        var str = [
//                   'script.',
//                   '  p foo',
//                   '',
//                   'script(type="text/template")',
//                   '  p foo',
//                   '',
//                   'script(type="text/template").',
//                   '  p foo'
//                   ].join('\n');
//
//        var html = [
//                    '<script>p foo\n</script>',
//                    '<script type="text/template"><p>foo</p></script>',
//                    '<script type="text/template">p foo</script>'
//                    ].join('');
//
//        renderEquals(html, str);
//      });
//
//      test('should support comments', (){
//        // Regular
//        var str = [
//                   '//foo',
//                   'p bar'
//                   ].join('\n');
//
//        var html = [
//                    '<!--foo-->',
//                    '<p>bar</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Arbitrary indentation
//
//        var str = [
//                   '     //foo',
//                   'p bar'
//                   ].join('\n');
//
//        var html = [
//                    '<!--foo-->',
//                    '<p>bar</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Between tags
//
//        var str = [
//                   'p foo',
//                   '// bar ',
//                   'p baz'
//                   ].join('\n');
//
//        var html = [
//                    '<p>foo</p>',
//                    '<!-- bar -->',
//                    '<p>baz</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Quotes
//
//        var str = "<!-- script(src: '/js/validate.js') -->",
//            js = "// script(src: '/js/validate.js') ";
//        renderEquals(str, js);
//      });
//
//      test('should support unbuffered comments', (){
//        var str = [
//                   '//- foo',
//                   'p bar'
//                   ].join('\n');
//
//        var html = [
//                    '<p>bar</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   'p foo',
//                   '//- bar ',
//                   'p baz'
//                   ].join('\n');
//
//        var html = [
//                    '<p>foo</p>',
//                    '<p>baz</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//      });
//
//      test('should support literal html', (){
//        renderEquals('<!--[if IE lt 9]>weeee<![endif]-->', '<!--[if IE lt 9]>weeee<![endif]-->');
//      });
//
//      test('should support code', (){
//        renderEquals('test', '!= "test"');
//        renderEquals('test', '= "test"');
//        renderEquals('test', '- var foo = "test"\n=foo');
//        renderEquals('foo<em>test</em>bar', '- var foo = "test"\n| foo\nem= foo\n| bar');
//        renderEquals('test<h2>something</h2>', '!= "test"\nh2 something');
//
//        var str = [
//                   '- var foo = "<script>";',
//                   '= foo',
//                   '!= foo'
//                   ].join('\n');
//
//        var html = [
//                    '&lt;script&gt;',
//                    '<script>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var foo = "<script>";',
//                   '- if (foo)',
//                   '  p= foo'
//                   ].join('\n');
//
//        var html = [
//                    '<p>&lt;script&gt;</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var foo = "<script>";',
//                   '- if (foo)',
//                   '  p!= foo'
//                   ].join('\n');
//
//        var html = [
//                    '<p><script></p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var foo;',
//                   '- if (foo)',
//                   '  p.hasFoo= foo',
//                   '- else',
//                   '  p.noFoo no foo'
//                   ].join('\n');
//
//        var html = [
//                    '<p class="noFoo">no foo</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var foo;',
//                   '- if (foo)',
//                   '  p.hasFoo= foo',
//                   '- else if (true)',
//                   '  p kinda foo',
//                   '- else',
//                   '  p.noFoo no foo'
//                   ].join('\n');
//
//        var html = [
//                    '<p>kinda foo</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   'p foo',
//                   '= "bar"',
//                   ].join('\n');
//
//        var html = [
//                    '<p>foo</p>bar'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   'title foo',
//                   '- if (true)',
//                   '  p something',
//                   ].join('\n');
//
//        var html = [
//                    '<title>foo</title><p>something</p>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   'foo',
//                   '  bar= "bar"',
//                   '    baz= "baz"',
//                   ].join('\n');
//
//        var html = [
//                    '<foo>',
//                    '<bar>bar',
//                    '<baz>baz</baz>',
//                    '</bar>',
//                    '</foo>'
//                    ].join('');
//
//        renderEquals(html, str);
//      });
//
//      test('should support - each', (){
//        // Array
//        var str = [
//                   '- var items = ["one", "two", "three"];',
//                   '- each item in items',
//                   '  li= item'
//                   ].join('\n');
//
//        var html = [
//                    '<li>one</li>',
//                    '<li>two</li>',
//                    '<li>three</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Any enumerable (length property)
//        var str = [
//                   '- var jQuery = { length: 3, 0: 1, 1: 2, 2: 3 };',
//                   '- each item in jQuery',
//                   '  li= item'
//                   ].join('\n');
//
//        var html = [
//                    '<li>1</li>',
//                    '<li>2</li>',
//                    '<li>3</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Empty array
//        var str = [
//                   '- var items = [];',
//                   '- each item in items',
//                   '  li= item'
//                   ].join('\n');
//
//        renderEquals('', str);
//
//        // Object
//        var str = [
//                   '- var obj = { foo: "bar", baz: "raz" };',
//                   '- each val in obj',
//                   '  li= val'
//                   ].join('\n');
//
//        var html = [
//                    '<li>bar</li>',
//                    '<li>raz</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Complex
//        var str = [
//                   '- var obj = { foo: "bar", baz: "raz" };',
//                   '- each key in Object.keys(obj)',
//                   '  li= key'
//                   ].join('\n');
//
//        var html = [
//                    '<li>foo</li>',
//                    '<li>baz</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Keys
//        var str = [
//                   '- var obj = { foo: "bar", baz: "raz" };',
//                   '- each val, key in obj',
//                   '  li #{key}: #{val}'
//                   ].join('\n');
//
//        var html = [
//                    '<li>foo: bar</li>',
//                    '<li>baz: raz</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        // Nested
//        var str = [
//                   '- var users = [{ 'name': "tj" }]',
//                   '- each user in users',
//                   '  - each val, key in user',
//                   '    li #{key} #{val}',
//                   ].join('\n');
//
//        var html = [
//                    '<li>name tj</li>'
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var users = ["tobi", "loki", "jane"]',
//                   'each user in users',
//                   '  li= user',
//                   ].join('\n');
//
//        var html = [
//                    '<li>tobi</li>',
//                    '<li>loki</li>',
//                    '<li>jane</li>',
//                    ].join('');
//
//        renderEquals(html, str);
//
//        var str = [
//                   '- var users = ["tobi", "loki", "jane"]',
//                   'for user in users',
//                   '  li= user',
//                   ].join('\n');
//
//        var html = [
//                    '<li>tobi</li>',
//                    '<li>loki</li>',
//                    '<li>jane</li>',
//                    ].join('');
//
//        renderEquals(html, str);
//      });
//
//      test('should support if', (){
//        var str = [
//                   '- var users = ["tobi", "loki", "jane"]',
//                   'if users.length',
//                   '  p users: #{users.length}',
//                   ].join('\n');
//
//        renderEquals('<p>users: 3</p>', str);
//
//        renderEquals('<iframe foo="bar"></iframe>', 'iframe(foo="bar")');
//      });
//
//      test('should support unless', (){
//        var str = [
//                   '- var users = ["tobi", "loki", "jane"]',
//                   'unless users.length',
//                   '  p no users',
//                   ].join('\n');
//
//        renderEquals('', str);
//
//        var str = [
//                   '- var users = []',
//                   'unless users.length',
//                   '  p no users',
//                   ].join('\n');
//
//        renderEquals('<p>no users</p>', str);
//      });
//
//      test('should support else', (){
//        var str = [
//                   '- var users = []',
//                   'if users.length',
//                   '  p users: #{users.length}',
//                   'else',
//                   '  p users: none',
//                   ].join('\n');
//
//        renderEquals('<p>users: none</p>', str);
//      });
//
//      test('should else if', (){
//        var str = [
//                   '- var users = ["tobi", "jane", "loki"]',
//                   'for user in users',
//                   '  if user == "tobi"',
//                   '    p awesome #{user}',
//                   '  else if user == "jane"',
//                   '    p lame #{user}',
//                   '  else',
//                   '    p #{user}',
//                   ].join('\n');
//
//        renderEquals('<p>awesome tobi</p><p>lame jane</p><p>loki</p>', str);
//      });
//
//      test('should include block', (){
//        var str = [
//                   'html',
//                   '  head',
//                   '    include fixtures/scripts',
//                   '      scripts(src="/app.js")',
//                   ].join('\n');
//
//        renderEquals('<html><head><script src=\"/jquery.js\"></script><script src=\"/caustic.js\"></script><scripts src=\"/app.js\"></scripts></head></html>'
//            , str, { filename: __dirname + '/jade.test.js' });
//      });
//    });
//
//    group('.)', (){
//      test('should support .str, fn)', (){
//        jade.'p foo bar', function(err, str){
//          assert.ok(!err);
//          renderEquals('<p>foo bar</p>', str);
//        });
//      });
//
//      test('should support .str, options, fn)', (){
//        jade.'p #{foo}', { foo: 'bar' }, function(err, str){
//          assert.ok(!err);
//          renderEquals('<p>bar</p>', str);
//        });
//      });
//
//      test('should support .str, options, fn) cache', (){
//        jade.'p bar', { cache: true }, function(err, str){
//          assert.ok(/the "filename" option is required for caching/.test(err.message);
//        });
//
//              jade.'p foo bar', { cache: true, filename: 'test' }, function(err, str){
//                assert.ok(!err);
//                renderEquals('<p>foo bar</p>', str);
//              });
//      });
//
//      test('should support .compile()', (){
//        var fn = jade.compile('p foo');
//        renderEquals('<p>foo</p>', fn();
//      });
//
//      test('should support .compile() locals', (){
//        var fn = jade.compile('p= foo');
//        renderEquals('<p>bar</p>', fn({ foo: 'bar' });
//      });
//
//      test('should support .compile() no debug', (){
//        var fn = jade.compile('p foo\np #{bar}', {compileDebug: false});
//        renderEquals('<p>foo</p><p>baz</p>', fn({bar: 'baz'});
//      });
//
//      test('should support .compile() no debug and global helpers', (){
//        var fn = jade.compile('p foo\np #{bar}', {compileDebug: false, helpers: 'global'});
//        renderEquals('<p>foo</p><p>baz</p>', fn({bar: 'baz'});
//      });
//
//      test('should support null attrs on tag', (){
//        var tag = new jade.nodes.Tag('a'),
//            name = 'href',
//            val = '"/"';
//        tag.setAttribute(name, val)
//        renderEquals(tag.getAttribute(name), val)
//        tag.removeAttribute(name)
//        assert.ok(!tag.getAttribute(name))
//      });
//
//      test('should support assignment', (){
//        renderEquals('<div>5</div>', 'a = 5;\ndiv= a');
//        renderEquals('<div>5</div>', 'a = 5\ndiv= a');
//        renderEquals('<div>foo bar baz</div>', 'a = "foo bar baz"\ndiv= a');
//        renderEquals('<div>5</div>', 'a = 5      \ndiv= a');
//        renderEquals('<div>5</div>', 'a = 5      ; \ndiv= a');
//
//        var fn = jade.compile('test = local\np=test');
//        renderEquals('<p>bar</p>', fn({ local: 'bar' });
//      });
//
//      test('should be reasonably fast', (){
//        jade.compile(perfTest, {})
//      })
    });
  });  
}