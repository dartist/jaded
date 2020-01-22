import 'dart:io';
import 'package:test/test.dart';
import 'package:jaded/jaded.dart';
import 'package:jaded/jaded.dart' as jade;

Future<String> renderEquals(String expected, String jade,
    {Map locals,
    bool debug = false,
    bool colons = false,
    String doctype,
    String filename,
    String reason}) {
  locals ??= {};
  var fn = compile(jade,
      locals: locals,
      debug: debug,
      colons: colons,
      doctype: doctype,
      filename: filename);
  return fn(locals).then(expectAsync1((html) {
    fn({'__shutdown': true}).then((done) {
      expect(html, equals(expected), reason: reason);
    });
  })).catchError((err) {
    print('$err: in $jade');
  });
}

void subGroup(String groupName, String testName, List<dynamic> list,
    {bool doctype = false, bool reason = false, bool locals = false}) {
  return group('$groupName:', () {
    var testList = list;

    var counter = 1;
    for (var el in testList) {
      test('$testName: $counter', () {
        var doc = el.length > 2 && doctype == true ? el[2] : null;
        var reas = el.length > 2 && reason == true ? el[2] : null;
        Map<dynamic, dynamic> locs =
            el.length > 2 && locals == true && el[2] is Map ? el[2] : null;
        renderEquals(el[0], el[1], doctype: doc, reason: reas, locals: locs);
      });
      counter++;
    }
  });
}

void main() {
  var __dirname = '.';
  var perfTest = File('$__dirname/fixtures/perf.jade').readAsStringSync();

  void runGroups(int groupNo, a, fn) {
    switch (groupNo) {
      case 0:
// Comment out groups you dont want to run
// Uncomment groups to run
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
        group(a, fn);
    }
  }

  group('jade', () {
//    test('--adhoc test', (){
//      jade.compile(perfTest)({'report':[]}).then(expectAsync1((str){
//        assert(true);
//      }));
//    });

    runGroups(1, '.compile()', () {
      subGroup(
          'doctype testing',
          'should support doctypes',
          [
            ['<?xml version="1.0" encoding="utf-8" ?>', '!!! xml'],
            ['<!DOCTYPE html>', 'doctype html'],
            ['<!DOCTYPE foo bar baz>', 'doctype foo bar baz'],
            ['<!DOCTYPE html>', '!!! 5'],
            ['<!DOCTYPE html>', '!!!', 'html'],
            ['<!DOCTYPE html>', '!!! html', 'xml'],
            ['<html></html>', 'html'],
            ['<!DOCTYPE html><html></html>', 'html', 'html'],
            [
              '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN>',
              'doctype html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN'
            ]
          ],
          doctype: true);

      subGroup(
          'line ending testing',
          'should support line endings',
          [
            [
              ['<p></p>', '<div></div>', '<img/>'].join(''),
              ['p', 'div', 'img'].join('\r\n')
            ],
            [
              ['<p></p>', '<div></div>', '<img/>'].join(''),
              ['p', 'div', 'img'].join('\r')
            ],
            [
              ['<p></p>', '<div></div>', '<img>'].join(''),
              ['p', 'div', 'img'].join('\r\n'),
              'html'
            ]
          ],
          doctype: true);

      subGroup('single quotes testing', 'should support single quotes', [
        ["<p>'foo'</p>", "p 'foo'"],
        ["<p>'foo'</p>", "p\n  | 'foo'"],
        ['<a href="/foo"></a>', "- var path = 'foo';\na(href='/' + path)"]
      ]);

      subGroup('block-expansion tests', 'should support block-expansion', [
        [
          '<li><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>',
          'li: a foo\nli: a bar\nli: a baz'
        ],
        [
          '<li class=\"first\"><a>foo</a></li><li><a>bar</a></li><li><a>baz</a></li>',
          'li.first: a foo\nli: a bar\nli: a baz'
        ],
        ['<div class="foo"><div class="bar">baz</div></div>', '.foo: .bar baz']
      ]);

      subGroup(
          'tags support testing',
          'should support tags',
          [
            [
              ['<p></p>', '<div></div>', '<img/>'].join(''),
              ['p', 'div', 'img'].join('\n'),
              'Test basic tags'
            ],
            ['<fb:foo-bar></fb:foo-bar>', 'fb:foo-bar', 'Test hyphens'],
            ['<div class="something"></div>', 'div.something', 'Test classes'],
            ['<div id="something"></div>', 'div#something', 'Test ids'],
            [
              '<div class="something"></div>',
              '.something',
              'Test stand-alone classes'
            ],
            [
              '<div id="something"></div>',
              '#something',
              'Test stand-alone ids'
            ],
            ['<div id="foo" class="bar"></div>', '#foo.bar'],
            ['<div id="foo" class="bar"></div>', '.bar#foo'],
            ['<div id="foo" class="bar"></div>', 'div#foo(class="bar")'],
            ['<div id="foo" class="bar"></div>', 'div(class="bar")#foo'],
            ['<div id="bar" class="foo"></div>', 'div(id="bar").foo'],
            ['<div class="foo bar baz"></div>', 'div.foo.bar.baz'],
            ['<div class="foo bar baz"></div>', 'div(class="foo").bar.baz'],
            ['<div class="foo bar baz"></div>', 'div.foo(class="bar").baz'],
            ['<div class="foo bar baz"></div>', 'div.foo.bar(class="baz")'],
            ['<div class="a-b2"></div>', 'div.a-b2'],
            ['<div class="a_b2"></div>', 'div.a_b2'],
            ['<fb:user></fb:user>', 'fb:user'],
            ['<fb:user:role></fb:user:role>', 'fb:user:role'],
            ['<colgroup><col class="test"/></colgroup>', 'colgroup\n  col.test']
          ],
          reason: true);

      subGroup('nested tags testing', 'should support nested tags', [
        [
          [
            '<ul>',
            '<li>a</li>',
            '<li>b</li>',
            '<li><ul><li>c</li><li>d</li></ul></li>',
            '<li>e</li>',
            '</ul>'
          ].join(''),
          [
            'ul',
            '  li a',
            '  li b',
            '  li',
            '    ul',
            '      li c',
            '      li d',
            '  li e',
          ].join('\n')
        ],
        [
          '<a href="#">foo \nbar \nbaz</a>',
          ['a(href="#")', '  | foo ', '  | bar ', '  | baz'].join('\n')
        ],
        [
          [
            '<ul>',
            '<li>one</li>',
            '<ul>two',
            '<li>three</li>',
            '</ul>',
            '</ul>'
          ].join(''),
          ['ul', '  li one', '  ul', '    | two', '    li three'].join('\n'),
        ]
      ]);

      subGroup('variable length newlines testing',
          'should support variable length newlines', [
        [
          [
            '<ul>',
            '<li>a</li>',
            '<li>b</li>',
            '<li><ul><li>c</li><li>d</li></ul></li>',
            '<li>e</li>',
            '</ul>'
          ].join(''),
          [
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
          ].join('\n')
        ]
      ]);

      test('should support tab conversion', () {
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

      subGroup('newlines testing', 'should support newlines', [
        [
          [
            '<ul>',
            '<li>a</li>',
            '<li>b</li>',
            '<li><ul><li>c</li><li>d</li></ul></li>',
            '<li>e</li>',
            '</ul>'
          ].join(''),
          [
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
          ].join('\n')
        ],
        [
          ['<html>', '<head>', 'test', '</head>', '<body></body>', '</html>']
              .join(''),
          ['html', ' ', '  head', '    != "test"', '  ', '  ', '  ', '  body']
              .join('\n')
        ],
        ['<foo></foo>something<bar></bar>', 'foo\n= "something"\nbar'],
        [
          '<foo></foo>something<bar></bar>else',
          'foo\n= "something"\nbar\n= "else"'
        ]
      ]);

      subGroup('text support tests', 'should support text', [
        ['foo\nbar\nbaz', '| foo\n| bar\n| baz'],
        ['foo \nbar \nbaz', '| foo \n| bar \n| baz'],
        ['(hey)', '| (hey)'],
        ['some random text', '| some random text'],
        ['  foo', '|   foo'],
        ['  foo  ', '|   foo  '],
        ['  foo  \n bar    ', '|   foo  \n|  bar    ']
      ]);

      subGroup('pipe-less text testing', 'should support pipe-less text', [
        [
          '<pre><code><foo></foo><bar></bar></code></pre>',
          'pre\n  code\n    foo\n\n    bar'
        ],
        ['<p>foo\n\nbar</p>', 'p.\n  foo\n\n  bar'],
        ['<p>foo\n\n\n\nbar</p>', 'p.\n  foo\n\n\n\n  bar'],
        ['<p>foo\n  bar\nfoo</p>', 'p.\n  foo\n    bar\n  foo'],
        [
          '<script>s.parentNode.insertBefore(g,s)</script>',
          'script.\n  s.parentNode.insertBefore(g,s)\n'
        ],
        [
          '<script>s.parentNode.insertBefore(g,s)</script>',
          'script.\n  s.parentNode.insertBefore(g,s)'
        ]
      ]);

      subGroup('tag text testing', 'should support tag text', [
        ['<p>some random text</p>', 'p some random text'],
        ['<p>click<a>Google</a>.</p>', 'p\n  | click\n  a Google\n  | .'],
        ['<p>(parens)</p>', 'p (parens)'],
        ['<p foo="bar">(parens)</p>', 'p(foo="bar") (parens)'],
        [
          '<option value="">-- (optional) foo --</option>',
          'option(value="") -- (optional) foo --'
        ]
      ]);

      subGroup('tag text block testing', 'should support tag text block', [
        ['<p>foo \nbar \nbaz</p>', 'p\n  | foo \n  | bar \n  | baz'],
        ['<label>Password:<input/></label>', 'label\n  | Password:\n  input'],
        ['<label>Password:<input/></label>', 'label Password:\n  input']
      ]);

      subGroup(
          'tag text interpolation testing',
          'should support tag text interpolation',
          [
            [
              'yo, jade is cool',
              '| yo, #{name} is cool\n',
              {'name': 'jade'}
            ],
            [
              '<p>yo, jade is cool</p>',
              'p yo, #{name} is cool',
              {'name': 'jade'}
            ],
            [
              'yo, jade is cool',
              '| yo, #{name != null ? name : "jade"} is cool',
              {'name': null}
            ],
            [
              'yo, \'jade\' is cool',
              '| yo, #{name != null ? name : "\'jade\'"} is cool',
              {'name': null}
            ],
            [
              'foo &lt;script&gt; bar',
              '| foo #{code} bar',
              {'code': '<script>'}
            ],
            [
              'foo <script> bar',
              '| foo !{code} bar',
              {'code': '<script>'}
            ]
          ],
          locals: true);

      test('should support flexible indentation', () {
        renderEquals('<html><body><h1>Wahoo</h1><p>test</p></body></html>',
            'html\n  body\n   h1 Wahoo\n   p test');
      });

      subGroup('interpolation values testing',
          'should support interpolation values', [
        ['<p>Users: 15</p>', 'p Users: #{15}'],
        ['<p>Users: </p>', 'p Users: #{null}'],
        ['<p>Users: none</p>', 'p Users: #{null != null ? null : "none"}'],
        ['<p>Users: 0</p>', 'p Users: #{0}'],
        ['<p>Users: false</p>', 'p Users: #{false}']
      ]);
    });

    runGroups(2, '.compile()', () {
      subGroup('html 5 tests', 'should support test html 5 mode', [
        [
          '<!DOCTYPE html><input type="checkbox" checked>',
          '!!! 5\ninput(type="checkbox", checked)'
        ],
        [
          '<!DOCTYPE html><input type="checkbox" checked>',
          '!!! 5\ninput(type="checkbox", checked=true)'
        ],
        [
          '<!DOCTYPE html><input type="checkbox">',
          '!!! 5\ninput(type="checkbox", checked= false)'
        ]
      ]);

      subGroup('multi line attr tests', 'should support multi-line attrs', [
        [
          '<a foo="bar" bar="baz" checked="checked">foo</a>',
          'a(foo="bar"\n  bar="baz"\n  checked) foo'
        ],
        [
          '<a foo="bar" bar="baz" checked="checked">foo</a>',
          'a(foo="bar"\nbar="baz"\nchecked) foo'
        ],
        [
          '<a foo="bar" bar="baz" checked="checked">foo</a>',
          'a(foo="bar"\n,bar="baz"\n,checked) foo'
        ],
        [
          '<a foo="bar" bar="baz" checked="checked">foo</a>',
          'a(foo="bar",\nbar="baz",\nchecked) foo'
        ]
      ]);

      subGroup(
          'attr support tests',
          'should support attrs',
          [
            [
              '<img src="&lt;script&gt;"/>',
              'img(src="<script>")',
              'Test attr escaping'
            ],

            ['<a data-attr="bar"></a>', 'a(data-attr="bar")'],
            [
              '<a data-attr="bar" data-attr-2="baz"></a>',
              'a(data-attr="bar", data-attr-2="baz")'
            ],

            ['<a title="foo,bar"></a>', 'a(title= "foo,bar")'],
            [
              '<a title="foo,bar" href="#"></a>',
              'a(title= "foo,bar", href="#")'
            ],

            [
              '<p class="foo"></p>',
              "p(class='foo')",
              'Test single quoted attrs'
            ],
            [
              '<input type="checkbox" checked="checked"/>',
              'input( type="checkbox", checked )'
            ],
            [
              '<input type="checkbox" checked="checked"/>',
              'input( type="checkbox", checked = true )'
            ],
            [
              '<input type="checkbox"/>',
              'input(type="checkbox", checked= false)'
            ],
            [
              '<input type="checkbox"/>',
              'input(type="checkbox", checked= null)'
            ],

            ['<img src="/foo.png"/>', 'img(src="/foo.png")', 'Test attr ='],
            [
              '<img src="/foo.png"/>',
              'img(src  =  "/foo.png")',
              'Test attr = whitespace'
            ],
            ['<img src="/foo.png"/>', 'img(src="/foo.png")', 'Test attr :'],
            [
              '<img src="/foo.png"/>',
              'img(src  =  "/foo.png")',
              'Test attr : whitespace'
            ],

            [
              '<img src="/foo.png" alt="just some foo"/>',
              'img(src="/foo.png", alt="just some foo")'
            ],
            [
              '<img src="/foo.png" alt="just some foo"/>',
              'img(src = "/foo.png", alt = "just some foo")'
            ],

            ['<p class="foo,bar,baz"></p>', 'p(class="foo,bar,baz")'],
            [
              '<a href="http://google.com" title="Some : weird = title"></a>',
              'a(href= "http://google.com", title= "Some : weird = title")'
            ],
            ['<label for="name"></label>', 'label(for="name")'],
            [
              '<meta name="viewport" content="width=device-width"/>',
              "meta(name= 'viewport', content='width=device-width')",
              'Test attrs that contain attr separators'
            ],
            ['<div style="color= white"></div>', "div(style='color= white')"],
            ['<div style="color: white"></div>', "div(style='color: white')"],
            [
              '<p class="foo"></p>',
              "p('class'='foo')",
              'Test keys with single quotes'
            ],
            [
              '<p class="foo"></p>',
              "p(\"class\"= 'foo')",
              'Test keys with double quotes'
            ],

            ['<p data-lang="en"></p>', 'p(data-lang = "en")'],
            ['<p data-dynamic="true"></p>', 'p("data-dynamic"= "true")'],
            [
              '<p data-dynamic="true" class="name"></p>',
              'p("class"= "name", "data-dynamic"= "true")'
            ],
            ['<p data-dynamic="true"></p>', 'p(\'data-dynamic\'= "true")'],
            [
              '<p data-dynamic="true" class="name"></p>',
              'p(\'class\'= "name", \'data-dynamic\'= "true")'
            ],
            [
              '<p data-dynamic="true" yay="yay" class="name"></p>',
              'p(\'class\'= "name", \'data-dynamic\'= "true", yay)'
            ],

            [
              '<input checked="checked" type="checkbox"/>',
              'input(checked, type="checkbox")'
            ],

            [
              "<a data-foo='{\"foo\":\"bar\",\"bar\":\"baz\"}'></a>",
              'a(data-foo  = "{ \'foo\': \'bar\', \'bar\': \'baz\' }")'
            ],
            //side-effect with fakeEval using JSON always
            //  converted to double-quotes
            [
              '<a data-foo=\"{ &quot;foo&quot;: &quot;bar&quot;, &quot;bar&quot;: &quot;baz&quot; }\"></a>',
              "a(data-foo  = '{ \"foo\": \"bar\", \"bar\": \"baz\" }')"
            ],

            [
              '<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>',
              'meta(http-equiv="X-UA-Compatible", content="IE=edge,chrome=1")'
            ],

            [
              '<div style="background: url(/images/test.png)">Foo</div>',
              "div(style= 'background: url(/images/test.png)') Foo"
            ],
            [
              '<div style="background = url(/images/test.png)">Foo</div>',
              "div(style= 'background = url(/images/test.png)') Foo"
            ],
            ['<div style="foo">Foo</div>', "div(style= ['foo', 'bar'][0]) Foo"],
            [
              '<div style="bar">Foo</div>',
              "div(style= { 'foo': 'bar', 'baz': 'raz' }['foo']) Foo"
            ],
            ['<a href="def">Foo</a>', "a(href='abcdefg'.substring(3,6)) Foo"],
            [
              '<a href="def">Foo</a>',
              "a(href={'test': 'abcdefg'}['test'].substring(3,6)) Foo"
            ],
            [
              '<a href="def">Foo</a>',
              "a(href={'test': 'abcdefg'}['test'].substring(3,[0,6][1])) Foo"
            ],

            ['<rss xmlns:atom="atom"></rss>', 'rss(xmlns:atom=\"atom\")'],
            ['<rss xmlns:atom="atom"></rss>', "rss('xmlns:atom'=\"atom\")"],
            ['<rss xmlns:atom="atom"></rss>', "rss(\"xmlns:atom\"='atom')"],
            [
              '<rss xmlns:atom="atom" foo="bar"></rss>',
              "rss('xmlns:atom'=\"atom\", 'foo'= 'bar')"
            ],
            [
              "<a data-obj='{\"foo\":\"bar\"}'></a>",
              "a(data-obj= \"{ 'foo': 'bar' }\")"
            ],

            [
              '<meta content="what\'s up? \'weee\'"/>',
              'meta(content="what\'s up? \'weee\'")'
            ]
          ],
          reason: true);
    });

    runGroups(3, '.compile()', () {
      test('should support colons option', () {
        renderEquals('<a href="/bar"></a>', 'a(href:"/bar")', colons: true);
      });

      test('should support class attr array', () {
        renderEquals('<body class="foo bar baz"></body>',
            'body(class=["foo", "bar", "baz"])');
      });

      subGroup(
          'attr intepolation test',
          'should support attr interpolation',
          // Test single quote interpolation
          [
            [
              '<a href="/user/12">tj</a>',
              "a(href='/user/#{id}') #{name}",
              {'name': 'tj', 'id': 12}
            ],

            [
              '<a href="/user/12-tj">tj</a>',
              "a(href='/user/#{id}-#{name}') #{name}",
              {'name': 'tj', 'id': 12}
            ],

            [
              '<a href="/user/&lt;script&gt;">tj</a>',
              "a(href='/user/#{id}') #{name}",
              {'name': 'tj', 'id': '<script>'}
            ],

            // Test double quote interpolation
            [
              '<a href="/user/13">ds</a>',
              'a(href="/user/#{id}") #{name}',
              {'name': 'ds', 'id': 13}
            ],

            [
              '<a href="/user/13-ds">ds</a>',
              'a(href="/user/#{id}-#{name}") #{name}',
              {'name': 'ds', 'id': 13}
            ],

            [
              '<a href="/user/&lt;script&gt;">ds</a>',
              'a(href="/user/#{id}") #{name}',
              {'name': 'ds', 'id': '<script>'}
            ]
          ],
          locals: true);

      test('should support attr parens', () {
        renderEquals('<p foo="bar">baz</p>', 'p(foo=((("bar"))))= ((("baz")))');
      });

      subGroup(
          'code attrs testing',
          'should support code attrs',
          [
            [
              '<p></p>',
              'p(id= name)',
              {'name': null}
            ],
            [
              '<p></p>',
              'p(id= name)',
              {'name': false}
            ],
            [
              '<p id=""></p>',
              'p(id= name)',
              {'name': ''}
            ],
            [
              '<p id="tj"></p>',
              'p(id= name)',
              {'name': 'tj'}
            ],
            [
              '<p id="default"></p>',
              'p(id= name != null ? name : "default")',
              {'name': null}
            ],
            [
              '<p id="something"></p>',
              "p(id= 'something')",
              {'name': null}
            ],
            [
              '<p id="something"></p>',
              "p(id = 'something')",
              {'name': null}
            ],
            ['<p id="foo"></p>', "p(id= (true ? 'foo' : 'bar'))"],
            ['<option value="">Foo</option>', "option(value='') Foo"]
          ],
          locals: true);

      subGroup(
          'code attrs class testing',
          'should support code attrs class',
          [
            [
              '<p class="tj"></p>',
              'p(class= name)',
              {'name': 'tj'}
            ],
            [
              '<p class="tj"></p>',
              'p( class= name )',
              {'name': 'tj'}
            ],
            [
              '<p class="default"></p>',
              'p(class= name != null ? name : "default")',
              {'name': null}
            ],
            [
              '<p class="foo default"></p>',
              'p.foo(class= name != null ? name : "default")',
              {'name': null}
            ],
            [
              '<p class="default foo"></p>',
              'p(class= name != null ? name : "default").foo',
              {'name': null}
            ],
            [
              '<p id="default"></p>',
              'p(id = name != null ? name : "default")',
              {'name': null}
            ],
            ['<p id="user-1"></p>', 'p(id = "user-" + 1.toString())'],
            ['<p class="user-1"></p>', 'p(class = "user-" + 1.toString())']
          ],
          locals: true);

      subGroup('code buffering testing', 'should support code buffering', [
        ['<p></p>', 'p= null'],
        ['<p>0</p>', 'p= 0'],
        ['<p>false</p>', 'p= false']
      ]);

      test('should support script text', () {
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

      test('should support comments', () {
        // Regular
        var str = ['//foo', 'p bar'].join('\n');

        var html = ['<!--foo-->', '<p>bar</p>'].join('');

        renderEquals(html, str);
      });
      // Arbitrary indentation
      test('should support comments', () {
        var str = ['     //foo', 'p bar'].join('\n');

        var html = ['<!--foo-->', '<p>bar</p>'].join('');

        renderEquals(html, str);

        // Between tags
      });

      test('should support comments', () {
        var str = ['p foo', '// bar ', 'p baz'].join('\n');

        var html = ['<p>foo</p>', '<!-- bar -->', '<p>baz</p>'].join('');

        renderEquals(html, str);
      });
      // Quotes
      test('should support comments', () {
        var str = "<!-- script(src: '/js/validate.js') -->";
        var js = "// script(src: '/js/validate.js') ";
        renderEquals(str, js);
      });

      test('should support unbuffered comments', () {
        String str, html;
        str = ['//- foo', 'p bar'].join('\n');

        html = ['<p>bar</p>'].join('');

        renderEquals(html, str);
      });

      test('should support unbuffered comments', () {
        var str = ['p foo', '//- bar ', 'p baz'].join('\n');

        var html = ['<p>foo</p>', '<p>baz</p>'].join('');

        renderEquals(html, str);
      });

      test('should support literal html', () {
        renderEquals('<!--[if IE lt 9]>weeee<![endif]-->',
            '<!--[if IE lt 9]>weeee<![endif]-->');
      });

      subGroup('code support tests', 'should support code', [
        ['test', '!= "test"'],
        ['test', '= "test"'],
        ['test', '- var foo = "test";\n=foo'],
        ['foo<em>test</em>bar', '- var foo = "test";\n| foo\nem= foo\n| bar'],
        ['test<h2>something</h2>', '!= "test"\nh2 something'],
        [
          ['&lt;script&gt;', '<script>'].join(''),
          ['- var foo = "<script>";', '= foo', '!= foo'].join('\n')
        ],
        [
          ['<p>&lt;script&gt;</p>'].join(''),
          ['- var foo = "<script>";', '- if (foo != null)', '  p= foo']
              .join('\n')
        ],
        [
          ['<p><script></p>'].join(''),
          ['- var foo = "<script>";', '- if (foo != null)', '  p!= foo']
              .join('\n')
        ],
        [
          ['<p class="noFoo">no foo</p>'].join(''),
          [
            '- var foo;',
            '- if (foo != null)',
            '  p.hasFoo= foo',
            '- else',
            '  p.noFoo no foo'
          ].join('\n')
        ],
        [
          ['<p>kinda foo</p>'].join(''),
          [
            '- var foo;',
            '- if (foo != null)',
            '  p.hasFoo= foo',
            '- else if (true)',
            '  p kinda foo',
            '- else',
            '  p.noFoo no foo'
          ].join('\n')
        ],
        [
          ['<p>foo</p>bar'].join(''),
          [
            'p foo',
            '= "bar"',
          ].join('\n')
        ],
        [
          ['<title>foo</title><p>something</p>'].join(''),
          [
            'title foo',
            '- if (true)',
            '  p something',
          ].join('\n')
        ],
        [
          ['<foo>', '<bar>bar', '<baz>baz</baz>', '</bar>', '</foo>'].join(''),
          [
            'foo',
            '  bar= "bar"',
            '    baz= "baz"',
          ].join('\n')
        ]
      ]);

      subGroup('each tests', 'should support - each', [
        // Array
        [
          ['<li>one</li>', '<li>two</li>', '<li>three</li>'].join(''),
          [
            '- var items = ["one", "two", "three"];',
            '- each item in items',
            '  li= item'
          ].join('\n')
        ],

        // Any enumerable (length property)
        [
          ['<li>1</li>', '<li>2</li>', '<li>3</li>'].join(''),
          ['- var jQuery = [1, 2, 3 ];', '- each item in jQuery', '  li= item']
              .join('\n')
        ],

        // Empty array
        [
          '',
          ['- var items = [];', '- each item in items', '  li= item'].join('\n')
        ],
        [
          ['<li>bar</li>', '<li>raz</li>'].join(''),
          [
            '- var obj = { "foo": "bar", "baz": "raz" };',
            '- each val in obj',
            '  li= val'
          ].join('\n')
        ],

        [
          ['<li>foo</li>', '<li>baz</li>'].join(''),
          [
            '- var obj = { "foo": "bar", "baz": "raz" };',
            '- each key in obj.keys.toList()',
            '  li= key'
          ].join('\n')
        ],

        [
          ['<li>foo: bar</li>', '<li>baz: raz</li>'].join(''),
          [
            '- var obj = { "foo": "bar", "baz": "raz" };',
            '- each val, key in obj',
            '  li #{key}: #{val}'
          ].join('\n')
        ],

        [
          ['<li>name tj</li>'].join(''),
          [
            '- var users = [{ "name": "tj" }]',
            '- each user in users',
            '  - each val, key in user',
            '    li #{key} #{val}',
          ].join('\n')
        ],

        [
          [
            '<li>tobi</li>',
            '<li>loki</li>',
            '<li>jane</li>',
          ].join(''),
          [
            '- var users = ["tobi", "loki", "jane"]',
            'each user in users',
            '  li= user',
          ].join('\n')
        ],

        [
          [
            '<li>tobi</li>',
            '<li>loki</li>',
            '<li>jane</li>',
          ].join(''),
          [
            '- var users = ["tobi", "loki", "jane"]',
            'for user in users',
            '  li= user',
          ].join('\n')
        ]
      ]);

      test('should support if', () {
        var str = [
          '- var users = ["tobi", "loki", "jane"];',
          'if users.length > 0',
          '  p users: #{users.length}',
        ].join('\n');

        renderEquals('<p>users: 3</p>', str);
      });

      test('should support if', () {
        renderEquals('<iframe foo="bar"></iframe>', 'iframe(foo="bar")');
      });

      test('should support unless', () {
        var str = [
          '- var users = ["tobi", "loki", "jane"];',
          'unless users.length > 0',
          '  p no users',
        ].join('\n');

        renderEquals('', str);
      });

      test('should support unless', () {
        var str = [
          '- var users = [];',
          'unless users.length > 0',
          '  p no users',
        ].join('\n');

        renderEquals('<p>no users</p>', str);
      });

      test('should support else', () {
        var str = [
          '- var users = [];',
          'if users.length > 0',
          '  p users: #{users.length}',
          'else',
          '  p users: none',
        ].join('\n');

        renderEquals('<p>users: none</p>', str);
      });

      test('should else if', () {
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

      test('should include block', () {
        var str = [
          'html',
          '  head',
          '    include fixtures/scripts',
          '      scripts(src="/app.js")',
        ].join('\n');

        renderEquals(
            '<html><head><script src=\"/jquery.js\"></script><script src=\"/caustic.js\"></script><scripts src=\"/app.js\"></scripts></head></html>',
            str,
            filename: __dirname + '/jade.test.js');
      });
    });

    runGroups(4, '.render()', () {
      test('should support .str, fn)', () {
        jade.render('p foo bar').then(expectAsync1((str) {
          expect(str, equals('<p>foo bar</p>'));
        }));
      });

      test('should support .str, options, fn)', () {
        jade.render('p #{foo}', locals: {'foo': 'bar'}).then(
            expectAsync1((str) {
          expect(str, equals('<p>bar</p>'));
        }));
      });

      test('should support .str, options, fn) cache', () {
        jade.render('p bar', cache: true).catchError(expectAsync1((err) {
          var msg = err.toString();
          assert(RegExp(r'the "filename" option is required for caching')
              .hasMatch(msg));
        }));

        jade
            .render('p foo bar', cache: true, filename: 'test')
            .then(expectAsync1((str) {
          expect(str, equals('<p>foo bar</p>'));
        }));
      });

      test('should support .compile()', () {
        jade.compile('p foo')().then(expectAsync1((str) {
          expect(str, equals('<p>foo</p>'));
        }));
      });

      test('should support .compile() locals', () {
        jade.compile('p= foo')({'foo': 'bar'}).then(expectAsync1((str) {
          expect(str, equals('<p>bar</p>'));
        }));
      });

      test('should support .compile() no debug', () {
        jade
            .compile('p foo\np #{bar}', compileDebug: false)({'bar': 'baz'})
            .then(expectAsync1((str) {
          expect(str, equals('<p>foo</p><p>baz</p>'));
        }));
      });

      test('should support .compile() no debug and global helpers', () {
        jade
            .compile('p foo\np #{bar}', compileDebug: false)
            ({'helpers': 'global', 'bar': 'baz'})
            .then(expectAsync1((str) {
          expect(str, equals('<p>foo</p><p>baz</p>'));
        }));
      });

      // test('should support null attrs on tag', () {
      //   var tag = Tag('a');
      //   var name = 'href';
      //   var val = '"/"';

      //   tag.set_Attribute(name, val);
      //   expect(tag.get_Attribute(name), equals(val));
      //   tag.remove_Attribute(name);
      //   assert(tag.get_Attribute(name) == null);
      // });

      subGroup('assignment support tests', 'should support assignment', [
        ['<div>5</div>', 'a = 5;\ndiv= a'],
        ['<div>5</div>', 'a = 5\ndiv= a'],
        ['<div>foo bar baz</div>', 'a = "foo bar baz"\ndiv= a'],
        ['<div>5</div>', 'a = 5      \ndiv= a'],
        ['<div>5</div>', 'a = 5      ; \ndiv= a']
      ]);
      test('assignment support tests', () {
        jade
            .compile('test = local\np=test')({'local': 'bar'})
            .then(expectAsync1((str) {
          expect(str, equals('<p>bar</p>'));
        }));
      });
    });

    runGroups(5, 'custom tests', () {
      test('test scss filter', () async {
        var jadeStr = File('./cases/filters.scss.jade').readAsStringSync();
        var htmlStr = File('./cases/filters.scss.html').readAsStringSync();
        var fn = jade.compile(jadeStr);
        await fn().then((done) {
          expect(done, htmlStr);
        });
      });

      test('test sass filter', () async {
        var jadeStr = File('./cases/filters.sass.jade').readAsStringSync();
        var htmlStr = File('./cases/filters.sass.html').readAsStringSync();
        var fn = jade.compile(jadeStr);
        await fn().then((done) {
          expect(done, htmlStr);
        });
      });

      test('should be reasonably fast', () async {
        await jade.compile(perfTest)({'report': []}).then(expectAsync1((str) {
          assert(true);
        }));
      });

      test('test deeply-nested locals 1', () async {
        await renderEquals('<li>1</li><li>2</li><li>3</li>',
            'each arg in request["args"]\n  li= arg',
            locals: {
              'request': {
                'args': [1, 2, 3]
              }
            });
      });
      test('test deeply-nested locals 2', () async {
      renderEquals('<p>/foo</p>', 'p #{request["path"]}',locals:{
              'request': {'path': '/foo'}
            });
      });
    });
  });
}

class Foo {
  String bar;
  List<String> args;
}
