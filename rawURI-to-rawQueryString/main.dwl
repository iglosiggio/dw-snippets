
%dw 2.0
output application/json
var tests = [
    'http://test.com/',
    'http://test.com/another/thing#fragment',
    'http://test.com/another/thing?a=1&b=2',
    'http://test.com/another/thing?a=1&b=2#fragment',
    'http://test.com/another/thing#fragment_with_?_marks=yes',
    'http://test.com/another/thing?a=1&b=2&param_with_?_marks=yes',
]
---
tests map (($ scan /(?<=^[^#?]*\?)[^#]*/)[0][0] default '')
