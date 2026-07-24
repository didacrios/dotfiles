#!/usr/bin/env python3
import browser_cookie3
import http.cookiejar

cookie_file = 'cookies.txt'

cj = http.cookiejar.MozillaCookieJar(cookie_file)

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

for name, func in browsers:
    try:
        cookies = func()
        for cookie in cookies:
            if '.youtube.com' in cookie.domain or '.youtubemusic.com' in cookie.domain:
                cj.set_cookie(cookie)
        if cj.filename:
            print(f'Cookies de {name} exportades a {cookie_file}')
            break
    except Exception as e:
        print(f'Error amb {name}: {e}')
        continue

if not cj.filename:
    print('No s han trobat cookies de YouTube. Assegura\'t de tenir sessió iniciada a YouTube Music.')
