import "package:unittest/unittest.dart";
import "dart:io";
import "package:jaded/jaded.dart";
import "package:jaded/jaded.dart" as jade;

main(){

  renderEquals(String expected, String jade, {
    Map locals,
    bool debug:false,
    bool colons:false,
    String doctype,
    String filename,
    String reason
  }){
    if (locals == null)
      locals = {};
    RenderAsync fn = compile(jade,
        locals:locals, debug:debug, colons:colons, doctype:doctype, filename:filename);
    return fn(locals).then(expectAsync1((html){
      fn({"__shutdown":true}); //close isolate after use
      expect(html, equals(expected), reason:reason);
    })).catchError((err){
      print("$err: in $jade");
    });
  }

  String __dirname = ".";
  String perfTest = new File(__dirname + '/fixtures/perf.jade').readAsStringSync();

  //test passing tests
  ignore(a, fn){}
  runGroup(int groupNo, a, fn){
    switch(groupNo){
      case 0:
//Uncomment group to run
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:

        group(a, fn);
    }
  }

  group('jade', (){

//    test('--adhoc test', (){
//      jade.compile(perfTest)({'report':[]}).then(expectAsync1((str){
//        assert(true);
//      }));
//    });

    runGroup(1, '.compile()', (){
      test('should support doctypes', (){
        renderEquals('<?xml version="1.0" encoding="utf-8" ?>', '!!! xml');
        renderEquals('<!DOCTYPE html>', 'doctype html');
        renderEquals('<!DOCTYPE foo bar baz>', 'doctype foo bar baz');
        renderEquals('<!DOCTYPE html>', '!!! 5');
        renderEquals('<!DOCTYPE html>', '!!!', doctype:'html');
        renderEquals('<!DOCTYPE html>', '!!! html', doctype:'xml');
        renderEquals('<html></html>', 'html');
        renderEquals('<!DOCTYPE html><html></html>', 'html', doctype:'html');
        renderEquals('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN>', 'doctype html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN');
      });

//      test('should support Buffers', (){
//        renderEquals('<p>foo</p>', new Buffer('p foo'));
//      });

      test('should support line endings', (){
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

        renderEquals(html, str, doctype:'html');
      });

      test('should support single quotes', (){
        renderEquals("<p>'foo'</p>", "p 'foo'");
        renderEquals("<p>'foo'</p>", "p\n  | 'foo'");
        renderEquals('<a href="/foo"></a>', "- var path = 'foo';\na(href='/' + path)");
      });

      test('should support block-expansion', (){
        renderEquals("<li><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", "li: a foo\nli: a bar\nli: a baz");
        renderEquals("<li class=\"first\"><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>", "li.first: a foo\nli: a bar\nli: a baz");
        renderEquals('<div class="foo"><div class="bar">baz</div></div>', ".foo: .bar baz");
      });

      test('should support tags', (){
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

        renderEquals(html, str, reason:'Test basic tags');
        renderEquals('<fb:foo-bar></fb:foo-bar>', 'fb:foo-bar', reason:'Test hyphens');
        renderEquals('<div class="something"></div>', 'div.something', reason:'Test classes');
        renderEquals('<div id="something"></div>', 'div#something', reason:'Test ids');
        renderEquals('<div class="something"></div>', '.something', reason:'Test stand-alone classes');
        renderEquals('<div id="something"></div>', '#something', reason:'Test stand-alone ids');
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

      test('should support nested tags', (){
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

      test('should support variable length newlines', (){
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

      test('should support tab conversion', (){
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

      test('should support newlines', (){
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

      test('should support text', (){
        renderEquals('foo\nbar\nbaz', '| foo\n| bar\n| baz');
        renderEquals('foo \nbar \nbaz', '| foo \n| bar \n| baz');
        renderEquals('(hey)', '| (hey)');
        renderEquals('some random text', '| some random text');
        renderEquals('  foo', '|   foo');
        renderEquals('  foo  ', '|   foo  ');
        renderEquals('  foo  \n bar    ', '|   foo  \n|  bar    ');
      });

      test('should support pipe-less text', (){
        renderEquals('<pre><code><foo></foo><bar></bar></code></pre>', 'pre\n  code\n    foo\n\n    bar');
        renderEquals('<p>foo\n\nbar</p>', 'p.\n  foo\n\n  bar');
        renderEquals('<p>foo\n\n\n\nbar</p>', 'p.\n  foo\n\n\n\n  bar');
        renderEquals('<p>foo\n  bar\nfoo</p>', 'p.\n  foo\n    bar\n  foo');
        renderEquals('<script>s.parentNode.insertBefore(g,s)</script>', 'script.\n  s.parentNode.insertBefore(g,s)\n');
        renderEquals('<script>s.parentNode.insertBefore(g,s)</script>', 'script.\n  s.parentNode.insertBefore(g,s)');
      });

      test('should support tag text', (){
        renderEquals('<p>some random text</p>', 'p some random text');
        renderEquals('<p>click<a>Google</a>.</p>', 'p\n  | click\n  a Google\n  | .');
        renderEquals('<p>(parens)</p>', 'p (parens)');
        renderEquals('<p foo="bar">(parens)</p>', 'p(foo="bar") (parens)');
        renderEquals('<option value="">-- (optional) foo --</option>', 'option(value="") -- (optional) foo --');
      });

      test('should support tag text block', (){
        renderEquals('<p>foo \nbar \nbaz</p>', 'p\n  | foo \n  | bar \n  | baz');
        renderEquals('<label>Password:<input/></label>', 'label\n  | Password:\n  input');
        renderEquals('<label>Password:<input/></label>', 'label Password:\n  input');
      });

      test('should support tag text interpolation', (){
        renderEquals('yo, jade is cool', '| yo, #{name} is cool\n', locals:{ 'name': 'jade' });
        renderEquals('<p>yo, jade is cool</p>', 'p yo, #{name} is cool', locals:{ 'name': 'jade' });
        renderEquals('yo, jade is cool', '| yo, #{name != null ? name : "jade"} is cool', locals:{ 'name': null });
        renderEquals('yo, \'jade\' is cool', '| yo, #{name != null ? name : "\'jade\'"} is cool', locals:{ 'name': null });
        renderEquals('foo &lt;script&gt; bar', '| foo #{code} bar', locals:{ 'code': '<script>' });
        renderEquals('foo <script> bar', '| foo !{code} bar', locals:{ 'code': '<script>' });
      });

      test('should support flexible indentation', (){
        renderEquals('<html><body><h1>Wahoo</h1><p>test</p></body></html>', 'html\n  body\n   h1 Wahoo\n   p test');
      });

      test('should support interpolation values', (){
        renderEquals('<p>Users: 15</p>', 'p Users: #{15}');
        renderEquals('<p>Users: </p>', 'p Users: #{null}');
        renderEquals('<p>Users: none</p>', 'p Users: #{null != null ? null : "none"}');
        renderEquals('<p>Users: 0</p>', 'p Users: #{0}');
        renderEquals('<p>Users: false</p>', 'p Users: #{false}');
      });

    });

    runGroup(2, '.compile()', (){

      test('should support test html 5 mode', (){
        renderEquals('<!DOCTYPE html><input type="checkbox" checked>', '!!! 5\ninput(type="checkbox", checked)');
        renderEquals('<!DOCTYPE html><input type="checkbox" checked>', '!!! 5\ninput(type="checkbox", checked=true)');
        renderEquals('<!DOCTYPE html><input type="checkbox">', '!!! 5\ninput(type="checkbox", checked= false)');
      });

      test('should support multi-line attrs', (){
        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\n  bar="baz"\n  checked) foo');
        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\nbar="baz"\nchecked) foo');
        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar"\n,bar="baz"\n,checked) foo');
        renderEquals('<a foo="bar" bar="baz" checked="checked">foo</a>', 'a(foo="bar",\nbar="baz",\nchecked) foo');
      });

      test('should support attrs', (){
        renderEquals('<img src="&lt;script&gt;"/>', 'img(src="<script>")', reason:'Test attr escaping');

        renderEquals('<a data-attr="bar"></a>', 'a(data-attr="bar")');
        renderEquals('<a data-attr="bar" data-attr-2="baz"></a>', 'a(data-attr="bar", data-attr-2="baz")');

        renderEquals('<a title="foo,bar"></a>', 'a(title= "foo,bar")');
        renderEquals('<a title="foo,bar" href="#"></a>', 'a(title= "foo,bar", href="#")');

        renderEquals('<p class="foo"></p>', "p(class='foo')", reason:'Test single quoted attrs');
        renderEquals('<input type="checkbox" checked="checked"/>', 'input( type="checkbox", checked )');
        renderEquals('<input type="checkbox" checked="checked"/>', 'input( type="checkbox", checked = true )');
        renderEquals('<input type="checkbox"/>', 'input(type="checkbox", checked= false)');
        renderEquals('<input type="checkbox"/>', 'input(type="checkbox", checked= null)');

        renderEquals('<img src="/foo.png"/>', 'img(src="/foo.png")', reason:'Test attr =');
        renderEquals('<img src="/foo.png"/>', 'img(src  =  "/foo.png")', reason:'Test attr = whitespace');
        renderEquals('<img src="/foo.png"/>', 'img(src="/foo.png")', reason:'Test attr :');
        renderEquals('<img src="/foo.png"/>', 'img(src  =  "/foo.png")', reason:'Test attr : whitespace');

        renderEquals('<img src="/foo.png" alt="just some foo"/>', 'img(src="/foo.png", alt="just some foo")');
        renderEquals('<img src="/foo.png" alt="just some foo"/>', 'img(src = "/foo.png", alt = "just some foo")');

        renderEquals('<p class="foo,bar,baz"></p>', 'p(class="foo,bar,baz")');
        renderEquals('<a href="http://google.com" title="Some : weird = title"></a>', 'a(href= "http://google.com", title= "Some : weird = title")');
        renderEquals('<label for="name"></label>', 'label(for="name")');
        renderEquals('<meta name="viewport" content="width=device-width"/>', "meta(name= 'viewport', content='width=device-width')", reason:'Test attrs that contain attr separators');
        renderEquals('<div style="color= white"></div>', "div(style='color= white')");
        renderEquals('<div style="color: white"></div>', "div(style='color: white')");
        renderEquals('<p class="foo"></p>', "p('class'='foo')", reason:'Test keys with single quotes');
        renderEquals('<p class="foo"></p>', "p(\"class\"= 'foo')", reason:'Test keys with double quotes');

        renderEquals('<p data-lang="en"></p>', 'p(data-lang = "en")');
        renderEquals('<p data-dynamic="true"></p>', 'p("data-dynamic"= "true")');
        renderEquals('<p data-dynamic="true" class="name"></p>', 'p("class"= "name", "data-dynamic"= "true")');
        renderEquals('<p data-dynamic="true"></p>', 'p(\'data-dynamic\'= "true")');
        renderEquals('<p data-dynamic="true" class="name"></p>', 'p(\'class\'= "name", \'data-dynamic\'= "true")');
        renderEquals('<p data-dynamic="true" yay="yay" class="name"></p>', 'p(\'class\'= "name", \'data-dynamic\'= "true", yay)');

        renderEquals('<input checked="checked" type="checkbox"/>', 'input(checked, type="checkbox")');

        renderEquals("<a data-foo='{\"foo\":\"bar\",\"bar\":\"baz\"}'></a>", 'a(data-foo  = "{ \'foo\': \'bar\', \'bar\': \'baz\' }")');
        //side-effect with fakeEval using JSON always converted to double-quotes
        renderEquals("<a data-foo=\"{ &quot;foo&quot;: &quot;bar&quot;, &quot;bar&quot;: &quot;baz&quot; }\"></a>", "a(data-foo  = '{ \"foo\": \"bar\", \"bar\": \"baz\" }')");

        renderEquals('<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>', 'meta(http-equiv="X-UA-Compatible", content="IE=edge,chrome=1")');

        renderEquals('<div style="background: url(/images/test.png)">Foo</div>', "div(style= 'background: url(/images/test.png)') Foo");
        renderEquals('<div style="background = url(/images/test.png)">Foo</div>', "div(style= 'background = url(/images/test.png)') Foo");
        renderEquals('<div style="foo">Foo</div>', "div(style= ['foo', 'bar'][0]) Foo");
        renderEquals('<div style="bar">Foo</div>', "div(style= { 'foo': 'bar', 'baz': 'raz' }['foo']) Foo");
        renderEquals('<a href="def">Foo</a>', "a(href='abcdefg'.substring(3,6)) Foo");
        renderEquals('<a href="def">Foo</a>', "a(href={'test': 'abcdefg'}['test'].substring(3,6)) Foo");
        renderEquals('<a href="def">Foo</a>', "a(href={'test': 'abcdefg'}['test'].substring(3,[0,6][1])) Foo");

        renderEquals('<rss xmlns:atom="atom"></rss>', "rss(xmlns:atom=\"atom\")");
        renderEquals('<rss xmlns:atom="atom"></rss>', "rss('xmlns:atom'=\"atom\")");
        renderEquals('<rss xmlns:atom="atom"></rss>', "rss(\"xmlns:atom\"='atom')");
        renderEquals('<rss xmlns:atom="atom" foo="bar"></rss>', "rss('xmlns:atom'=\"atom\", 'foo'= 'bar')");
        renderEquals("<a data-obj='{\"foo\":\"bar\"}'></a>", "a(data-obj= \"{ 'foo': 'bar' }\")");

        renderEquals('<meta content="what\'s up? \'weee\'"/>', 'meta(content="what\'s up? \'weee\'")');
      });

    });

    runGroup(3, '.compile()', (){

      test('should support colons option', (){
        renderEquals('<a href="/bar"></a>', 'a(href:"/bar")', colons: true);
      });

      test('should support class attr array', (){
        renderEquals('<body class="foo bar baz"></body>', 'body(class=["foo", "bar", "baz"])');
      });

      test('should support attr interpolation', (){
        // Test single quote interpolation
        renderEquals('<a href="/user/12">tj</a>'
            , "a(href='/user/#{id}') #{name}", locals:{ 'name': 'tj', 'id': 12 });

        renderEquals('<a href="/user/12-tj">tj</a>'
            , "a(href='/user/#{id}-#{name}') #{name}", locals:{ 'name': 'tj', 'id': 12 });

        renderEquals('<a href="/user/&lt;script&gt;">tj</a>'
            , "a(href='/user/#{id}') #{name}", locals:{ 'name': 'tj', 'id': '<script>' });

        // Test double quote interpolation
        renderEquals('<a href="/user/13">ds</a>'
            , 'a(href="/user/#{id}") #{name}', locals:{ 'name': 'ds', 'id': 13 });

        renderEquals('<a href="/user/13-ds">ds</a>'
            , 'a(href="/user/#{id}-#{name}") #{name}', locals:{ 'name': 'ds', 'id': 13 });

        renderEquals('<a href="/user/&lt;script&gt;">ds</a>'
            , 'a(href="/user/#{id}") #{name}', locals:{ 'name': 'ds', 'id': '<script>' });
      });

      test('should support attr parens', (){
        renderEquals('<p foo="bar">baz</p>', 'p(foo=((("bar"))))= ((("baz")))');
      });

      test('should support code attrs', (){
        renderEquals('<p></p>', 'p(id= name)', locals:{ 'name': null });
        renderEquals('<p></p>', 'p(id= name)', locals:{ 'name': false });
        renderEquals('<p id=""></p>', 'p(id= name)', locals:{ 'name': '' });
        renderEquals('<p id="tj"></p>', 'p(id= name)', locals:{ 'name': 'tj' });
        renderEquals('<p id="default"></p>', 'p(id= name != null ? name : "default")', locals:{ 'name': null });
        renderEquals('<p id="something"></p>', "p(id= 'something')", locals:{ 'name': null });
        renderEquals('<p id="something"></p>', "p(id = 'something')", locals:{ 'name': null });
        renderEquals('<p id="foo"></p>', "p(id= (true ? 'foo' : 'bar'))");
        renderEquals('<option value="">Foo</option>', "option(value='') Foo");
      });

      test('should support code attrs class', (){
        renderEquals('<p class="tj"></p>', 'p(class= name)', locals:{ 'name': 'tj' });
        renderEquals('<p class="tj"></p>', 'p( class= name )', locals:{ 'name': 'tj' });
        renderEquals('<p class="default"></p>', 'p(class= name != null ? name : "default")', locals:{ 'name': null });
        renderEquals('<p class="foo default"></p>', 'p.foo(class= name != null ? name : "default")', locals:{ 'name': null });
        renderEquals('<p class="default foo"></p>', 'p(class= name != null ? name : "default").foo', locals:{ 'name': null });
        renderEquals('<p id="default"></p>', 'p(id = name != null ? name : "default")', locals:{ 'name': null });
        renderEquals('<p id="user-1"></p>', 'p(id = "user-" + 1.toString())');
        renderEquals('<p class="user-1"></p>', 'p(class = "user-" + 1.toString())');
      });

      test('should support code buffering', (){
        renderEquals('<p></p>', 'p= null');
        renderEquals('<p>0</p>', 'p= 0');
        renderEquals('<p>false</p>', 'p= false');
      });

      test('should support script text', (){
        var str = [
                   'script.',
                   '  p foo',
                   '',
                   'script(type="text/template")',
                   '  p foo',
                   '',
                   'script(type="text/template").',
                   '  p foo'
                   ].join('\n');

        var html = [
                    '<script>p foo\n</script>',
                    '<script type="text/template"><p>foo</p></script>',
                    '<script type="text/template">p foo</script>'
                    ].join('');

        renderEquals(html, str);
      });

      test('should support comments', (){
        String str, html;
        // Regular
        str = [
               '//foo',
               'p bar'
               ].join('\n');

        html = [
                '<!--foo-->',
                '<p>bar</p>'
                ].join('');

        renderEquals(html, str);

        // Arbitrary indentation

        str = [
               '     //foo',
               'p bar'
               ].join('\n');

        html = [
                '<!--foo-->',
                '<p>bar</p>'
                ].join('');

        renderEquals(html, str);

        // Between tags

        str = [
               'p foo',
               '// bar ',
               'p baz'
               ].join('\n');

        html = [
                '<p>foo</p>',
                '<!-- bar -->',
                '<p>baz</p>'
                ].join('');

        renderEquals(html, str);

        // Quotes

        str = "<!-- script(src: '/js/validate.js') -->";
        var js = "// script(src: '/js/validate.js') ";
        renderEquals(str, js);
      });

      test('should support unbuffered comments', (){
        String str, html;
        str = [
               '//- foo',
               'p bar'
               ].join('\n');

        html = [
                '<p>bar</p>'
                ].join('');

        renderEquals(html, str);

        str = [
               'p foo',
               '//- bar ',
               'p baz'
               ].join('\n');

        html = [
                '<p>foo</p>',
                '<p>baz</p>'
                ].join('');

        renderEquals(html, str);
      });

      test('should support literal html', (){
        renderEquals('<!--[if IE lt 9]>weeee<![endif]-->', '<!--[if IE lt 9]>weeee<![endif]-->');
      });

      test('should support code', (){
        String str, html;
        renderEquals('test', '!= "test"');
        renderEquals('test', '= "test"');
        renderEquals('test', '- var foo = "test";\n=foo');
        renderEquals('foo<em>test</em>bar', '- var foo = "test";\n| foo\nem= foo\n| bar');
        renderEquals('test<h2>something</h2>', '!= "test"\nh2 something');

        str = [
               '- var foo = "<script>";',
               '= foo',
               '!= foo'
               ].join('\n');

        html = [
                '&lt;script&gt;',
                '<script>'
                ].join('');

        renderEquals(html, str);

        str = [
               '- var foo = "<script>";',
               '- if (foo != null)',
               '  p= foo'
               ].join('\n');

        html = [
                '<p>&lt;script&gt;</p>'
                ].join('');

        renderEquals(html, str);

        str = [
               '- var foo = "<script>";',
               '- if (foo != null)',
               '  p!= foo'
               ].join('\n');

        html = [
                '<p><script></p>'
                ].join('');

        renderEquals(html, str);

        str = [
               '- var foo;',
               '- if (foo != null)',
               '  p.hasFoo= foo',
               '- else',
               '  p.noFoo no foo'
               ].join('\n');

        html = [
                '<p class="noFoo">no foo</p>'
                ].join('');

        renderEquals(html, str);

        str = [
               '- var foo;',
               '- if (foo != null)',
               '  p.hasFoo= foo',
               '- else if (true)',
               '  p kinda foo',
               '- else',
               '  p.noFoo no foo'
               ].join('\n');

        html = [
                '<p>kinda foo</p>'
                ].join('');

        renderEquals(html, str);

        str = [
               'p foo',
               '= "bar"',
               ].join('\n');

        html = [
                '<p>foo</p>bar'
                ].join('');

        renderEquals(html, str);

        str = [
               'title foo',
               '- if (true)',
               '  p something',
               ].join('\n');

        html = [
                '<title>foo</title><p>something</p>'
                ].join('');

        renderEquals(html, str);

        str = [
               'foo',
               '  bar= "bar"',
               '    baz= "baz"',
               ].join('\n');

        html = [
                '<foo>',
                '<bar>bar',
                '<baz>baz</baz>',
                '</bar>',
                '</foo>'
                ].join('');

        renderEquals(html, str);
      });

      test('should support - each', (){
        String str, html;

        // Array
        str = [
               '- var items = ["one", "two", "three"];',
               '- each item in items',
               '  li= item'
               ].join('\n');

        html = [
                '<li>one</li>',
                '<li>two</li>',
                '<li>three</li>'
                ].join('');

        renderEquals(html, str);

        // Any enumerable (length property)
        str = [
               '- var jQuery = [1, 2, 3 ];',
               '- each item in jQuery',
               '  li= item'
               ].join('\n');

        html = [
                '<li>1</li>',
                '<li>2</li>',
                '<li>3</li>'
                ].join('');

        renderEquals(html, str);

        // Empty array
        str = [
               '- var items = [];',
               '- each item in items',
               '  li= item'
               ].join('\n');

        renderEquals('', str);

        // Object
        str = [
               '- var obj = { "foo": "bar", "baz": "raz" };',
               '- each val in obj',
               '  li= val'
               ].join('\n');

        html = [
                '<li>bar</li>',
                '<li>raz</li>'
                ].join('');

        renderEquals(html, str);

        // Complex
        str = [
               '- var obj = { "foo": "bar", "baz": "raz" };',
               '- each key in obj.keys.toList()',
               '  li= key'
               ].join('\n');

        html = [
                '<li>foo</li>',
                '<li>baz</li>'
                ].join('');

        renderEquals(html, str);

        // Keys
        str = [
               '- var obj = { "foo": "bar", "baz": "raz" };',
               '- each val, key in obj',
               '  li #{key}: #{val}'
               ].join('\n');

        html = [
                '<li>foo: bar</li>',
                '<li>baz: raz</li>'
                ].join('');

        renderEquals(html, str);

        // Nested
        str = [
               '- var users = [{ "name": "tj" }]',
               '- each user in users',
               '  - each val, key in user',
               '    li #{key} #{val}',
               ].join('\n');

        html = [
                '<li>name tj</li>'
                ].join('');

        renderEquals(html, str);

        str = [
               '- var users = ["tobi", "loki", "jane"]',
               'each user in users',
               '  li= user',
               ].join('\n');

        html = [
                '<li>tobi</li>',
                '<li>loki</li>',
                '<li>jane</li>',
                ].join('');

        renderEquals(html, str);

        str = [
               '- var users = ["tobi", "loki", "jane"]',
               'for user in users',
               '  li= user',
               ].join('\n');

        html = [
                '<li>tobi</li>',
                '<li>loki</li>',
                '<li>jane</li>',
                ].join('');

        renderEquals(html, str);
      });

      test('should support if', (){
        var str = [
                   '- var users = ["tobi", "loki", "jane"];',
                   'if users.length > 0',
                   '  p users: #{users.length}',
                   ].join('\n');

        renderEquals('<p>users: 3</p>', str);

        renderEquals('<iframe foo="bar"></iframe>', 'iframe(foo="bar")');
      });

      test('should support unless', (){
        String str;
        str = [
               '- var users = ["tobi", "loki", "jane"];',
               'unless users.length > 0',
               '  p no users',
               ].join('\n');

        renderEquals('', str);

        str = [
               '- var users = [];',
               'unless users.length > 0',
               '  p no users',
               ].join('\n');

        renderEquals('<p>no users</p>', str);
      });

      test('should support else', (){
        var str = [
                   '- var users = [];',
                   'if users.length > 0',
                   '  p users: #{users.length}',
                   'else',
                   '  p users: none',
                   ].join('\n');

        renderEquals('<p>users: none</p>', str);
      });

      test('should else if', (){
        var str = [
                   '- var users = ["tobi", "jane", "loki"];',
                   'for user in users',
                   '  if user == "tobi"',
                   '    p awesome #{user}',
                   '  else if user == "jane"',
                   '    p lame #{user}',
                   '  else',
                   '    p #{user}',
                   ].join('\n');

        renderEquals('<p>awesome tobi</p><p>lame jane</p><p>loki</p>', str);
      });

      test('should include block', (){
        var str = [
                   'html',
                   '  head',
                   '    include fixtures/scripts',
                   '      scripts(src="/app.js")',
                   ].join('\n');

        renderEquals('<html><head><script src=\"/jquery.js\"></script><script src=\"/caustic.js\"></script><scripts src=\"/app.js\"></scripts></head></html>'
            , str, filename: __dirname + '/jade.test.js');
      });
    });

    runGroup(4, '.render()', (){
      test('should support .str, fn)', (){
        jade.render('p foo bar').then(expectAsync1((str){
          expect(str, equals('<p>foo bar</p>'));
        }));
      });

      test('should support .str, options, fn)', (){
        jade.render('p #{foo}', locals:{ 'foo': 'bar' }).then(expectAsync1((str){
          expect(str, equals('<p>bar</p>'));
        }));
      });

      test('should support .str, options, fn) cache', (){
        jade.render('p bar', cache: true).catchError(expectAsync1((Error err){
          var msg = err.toString();
          assert(new RegExp(r'the "filename" option is required for caching').hasMatch(msg));
        }));

        jade.render('p foo bar', cache:true, filename: 'test').then(expectAsync1((str){
          expect(str, equals('<p>foo bar</p>'));
        }));
      });

      test('should support .compile()', (){
        jade.compile('p foo')().then(expectAsync1((str){

          expect(str, equals('<p>foo</p>'));
        }));
      });

      test('should support .compile() locals', (){
        jade.compile('p= foo')({ 'foo': 'bar' }).then(expectAsync1((str){
          expect(str, equals('<p>bar</p>'));
        }));
      });

      test('should support .compile() no debug', (){
        jade.compile('p foo\np #{bar}', compileDebug: false)({ 'bar': 'baz'})
          .then(expectAsync1((str){
            expect(str, equals('<p>foo</p><p>baz</p>'));
          }));
      });

      test('should support .compile() no debug and global helpers', (){
        jade.compile('p foo\np #{bar}', compileDebug: false)({'helpers': 'global', 'bar': 'baz'})
          .then(expectAsync1((str){
            expect(str, equals('<p>foo</p><p>baz</p>'));
          }));
      });

      test('should support null attrs on tag', (){
        var tag = new Tag('a');
        var name = 'href';
        var val = '"/"';

        tag.setAttribute(name, val);
        expect(tag.getAttribute(name), equals(val));
        tag.removeAttribute(name);
        assert(tag.getAttribute(name) == null);
      });

      test('should support assignment', (){
        renderEquals('<div>5</div>', 'a = 5;\ndiv= a');
        renderEquals('<div>5</div>', 'a = 5\ndiv= a');
        renderEquals('<div>foo bar baz</div>', 'a = "foo bar baz"\ndiv= a');
        renderEquals('<div>5</div>', 'a = 5      \ndiv= a');
        renderEquals('<div>5</div>', 'a = 5      ; \ndiv= a');

        jade.compile('test = local\np=test')({ 'local': 'bar' })
          .then(expectAsync1((str){
            expect(str, equals('<p>bar</p>'));
          }));
      });

      test('should be reasonably fast', (){
        jade.compile(perfTest)({'report':[]}).then(expectAsync1((str){
          assert(true);
        }));
      });

    });

    runGroup(5, 'custom tests', (){

      test('should support deep-nested var references', (){
        renderEquals('<p>/foo</p>', 'p #{request["path"]}',
            locals:{'request': {'path': '/foo'}});

        renderEquals('<li>1</li><li>2</li><li>3</li>',
            'each arg in request["args"]\n  li= arg',
            locals:{'request': {'args': [1,2,3]}});

//Can't pass non-primitave objects to isolates
//      renderEquals('<p>/foo</p>','p #{foo.bar}',
//        locals:{'foo': new Foo()..bar="/foo"});

//      renderEquals('<li>1</li>\n<li>2</li>\n<li>3</li>\n',
//        'each arg in foo.args\n  li= arg',
//         locals:{'foo': new Foo()..args=[1,2,3]});
      });
    });

  });
}


class Foo {
  String bar;
  List<String> args;
}
