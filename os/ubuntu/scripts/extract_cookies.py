#!/usr/bin/env python3
import browser_cookie3
import http.cookiejar
import os

cookie_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cookies.txt')

browsers = []
try:
    browsers.append(('chrome', browser_cookie3.chrome))
except browser_cookie3.BrowserError:
    pass
try:
    browsers.append(('firefox', browser_cookie3.firefox))
except browser_cookie3.BrowserError:
    pass
try:
    browsers.append(('edge', browser_cookie3.edge))
except browser_cookie3.BrowserError:
    pass

cj = http.cookiejar.MozillaCookieJar(cookie_file)
found = False

for name, func in browsers:
    try:
        cookies = func()
        yt_cookies = [c for c in cookies if '.youtube.com' in c.domain or '.youtubemusic.com' in c.domain]
        if yt_cookies:
            for cookie in yt_cookies:
                cj.set_cookie(cookie)
            cj.save()
            print(f'{len(yt_cookies)} cookies de YouTube de {name} guardades a {cookie_file}')
            found = True
            break
    except Exception as e:
        print(f'Error amb {name}: {e}')
        continue

if not found:
    print('No s han trobat cookies de YouTube. Assegura\'t de tenir sessió iniciada a YouTube Music.')