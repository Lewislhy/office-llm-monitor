#!/usr/bin/env python3
"""Checks the single-file page for the mistakes this project has actually shipped.

Every rule here exists because it broke something once: a stray closing brace that disabled
the rest of the stylesheet, a tag that was never closed, an icon that was referenced after
being renamed.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGES = [f for f in os.listdir(ROOT) if f.endswith('.html')]
bad = []


def say(page, msg):
    bad.append('%s: %s' % (page, msg)); print('  FAIL %s: %s' % (page, msg))


for name in sorted(PAGES):
    src = open(os.path.join(ROOT, name), encoding='utf-8', errors='replace').read()

    for tag in ('script', 'style', 'svg'):
        o = len(re.findall(r'<%s[\s>]' % tag, src, re.I))
        c = len(re.findall(r'</%s>' % tag, src, re.I))
        if o != c:
            say(name, '%d <%s> vs %d </%s>' % (o, tag, c, tag))

    if src.count('{') != src.count('}'):
        say(name, 'braces do not balance: %d { and %d }' % (src.count('{'), src.count('}')))
    if src.count('(') != src.count(')'):
        say(name, 'parentheses do not balance: %d ( and %d )' % (src.count('('), src.count(')')))

    for ref in sorted(set(re.findall(r'["\'](/?app/[\w.\-]+)["\']', src))):
        if not os.path.exists(os.path.join(ROOT, ref.lstrip('/'))):
            say(name, 'references %s, which does not exist' % ref)

    if '<title>' not in src.lower():
        say(name, 'no <title>')

    print('  ok   %s (%d KB)' % (name, len(src) // 1024) if not bad or bad[-1].split(':')[0] != name else '')

if bad:
    print('\n%d problem(s)' % len(bad)); sys.exit(1)
print('\npages look fine')
