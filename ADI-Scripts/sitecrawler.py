#!/usr/bin/python

import re
import mechanize

br = mechanize.Browser()
br.open("http://www.example.com/")
# follow second link with element text matching regular expression
response1 = br.follow_link(text_regex=r"cheese\s*shop", nr=1)
assert br.viewing_html()
print br.title()
print response1.geturl()
print response1.info()  # headers
print response1.read()  # body
