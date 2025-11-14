<img src="https://raw.githubusercontent.com/Vizonex/Winloop/main/winloop.png" width="200px"/>
<a href="https://github.com/psf/black"><img alt="Code style: black" src="https://img.shields.io/badge/code%20style-black-000000.svg"></a>


# Winloop
[![PyPI version](https://badge.fury.io/py/winloop.svg)](https://badge.fury.io/py/winloop)
![PyPI - Downloads](https://img.shields.io/pypi/dm/winloop)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache-yellow.svg)](https://opensource.org/licenses/Apache-2-0)

An alternative library for uvloop compatibility with Windows because let's face it. Windows' Python asyncio standard library is garbage, especially when Windows Defender decides to eat half of your RAM.
I never really liked the fact that I couldn't make anything run faster especially when you have fiber internet connections in place and you've done all the optimizations you could possibly think of. It always felt disappointing when `libuv` is available for Windows [but Windows was never compatible with uvloop.](https://github.com/MagicStack/uvloop/issues/14#issuecomment-575826367])

Since nobody was willing to step in after so many years of waiting, I went ahead and downloaded the source code for uvloop and started modifying the source code to be Windows compatible by carefully removing and changing parts that were not made for Windows. Many hours of research went into making this library.

The differences with __uvloop__ is that forking has been fully disabled and some smaller API calls had to be changed, error handling has been carefully modified and subprocesses release the GIL instead of forking out...

There is a performance increase of about 5 times with Winloop compared to using the `WindowsSelectorEventLoopPolicy` and `WindowsProactorEventLoopPolicy` which have been known to trigger SSL problems in `Python 3.9`. Winloop is a very good replacement for solving those SSL problems as well. This library also has comparable performance to its brother uvloop.



## How to install Winloop on your Windows Operating System

```
pip install winloop
```

You can also clone the repository and build the extension yourself by running the command below if you wish to use or build this library locally. Note that you will need Cython and The Visual C++ extensions
to compile this library on your own.

```
python setup.py build_ext --inplace
```

## Reporting issues

If you find any bugs with this library be sure to open up an issue in the [issuetracker](https://github.com/Vizonex/Winloop/issues). Me and other contributors will be happy try to help you figure out and diagnose your problems.

## Making pull requests
We encourage anyone to make pull-requests to Winloop, containing anything from spelling mistakes to vulnerability patches. Every little bit helps keep this library maintained and alive.
Make sure that you are able to compile the library with the steps shown above. We plan to implement a nightly workflow to verify one's pull-request in the future.



```python
try:
    import aiohttp
    import aiohttp.web
except ImportError:
    skip_tests = True
else:
    skip_tests = False

import asyncio
import unittest
import weakref
import winloop
import sys

class TestAioHTTP(unittest.TestCase):
    def __init__(self, methodName: str = "test_aiohttp_basic_1") -> None:
        super().__init__(methodName)


    def setUp(self):
        self.loop = asyncio.get_event_loop()

    def test_aiohttp_basic_1(self):
        PAYLOAD = '<h1>It Works!</h1>' * 10000

        async def on_request(request):
            return aiohttp.web.Response(text=PAYLOAD)

        asyncio.set_event_loop(self.loop)
        app = aiohttp.web.Application()
        app.router.add_get('/', on_request)

        runner = aiohttp.web.AppRunner(app)
        self.loop.run_until_complete(runner.setup())
        site = aiohttp.web.TCPSite(runner, '0.0.0.0', '10000')
        self.loop.run_until_complete(site.start())
        port = site._server.sockets[0].getsockname()[1]

        async def test():
            # Make sure we're using the correct event loop.
            self.assertIs(asyncio.get_event_loop(), self.loop)

            for addr in (('localhost', port),
                         ('127.0.0.1', port)):
                async with aiohttp.ClientSession() as client:
                    async with client.get('http://{}:{}'.format(*addr)) as r:
                        self.assertEqual(r.status, 200)
                        result = await r.text()
                        self.assertEqual(result, PAYLOAD)

        self.loop.run_until_complete(test())
        self.loop.run_until_complete(runner.cleanup())

    def test_aiohttp_graceful_shutdown(self):
        async def websocket_handler(request):
            ws = aiohttp.web.WebSocketResponse()
            await ws.prepare(request)
            request.app['websockets'].add(ws)
            try:
                async for msg in ws:
                    await ws.send_str(msg.data)
            finally:
                request.app['websockets'].discard(ws)
            return ws

        async def on_shutdown(app):
            for ws in set(app['websockets']):
                await ws.close(
                    code=aiohttp.WSCloseCode.GOING_AWAY,
                    message='Server shutdown')

        asyncio.set_event_loop(self.loop)
        app = aiohttp.web.Application()
        app.router.add_get('/', websocket_handler)
        app.on_shutdown.append(on_shutdown)
        app['websockets'] = weakref.WeakSet()

        runner = aiohttp.web.AppRunner(app)
        self.loop.run_until_complete(runner.setup())
        site = aiohttp.web.TCPSite(runner, '0.0.0.0', '10000')
        self.loop.run_until_complete(site.start())
        port = site._server.sockets[0].getsockname()[1]

        async def client():
            async with aiohttp.ClientSession() as client:
                async with client.ws_connect(
                        'http://127.0.0.1:{}'.format(port)) as ws:
                    await ws.send_str("hello")
                    async for msg in ws:
                        assert msg.data == "hello"

        client_task = asyncio.ensure_future(client())

        async def stop():
            await asyncio.sleep(0.1)
            try:
                await asyncio.wait_for(runner.cleanup(), timeout=0.1)
            except Exception as e:
                print(e)
            finally:
                try:
                    client_task.cancel()
                    await client_task
                except asyncio.CancelledError:
                    pass

        self.loop.run_until_complete(stop())



if __name__ == "__main__":
    # print("tesing without winloop")
    # asyncio.DefaultEventLoopPolicy = asyncio.WindowsSelectorEventLoopPolicy
    # asyncio.DefaultEventLoopPolicy = asyncio.WindowsProactorEventLoopPolicy
    unittest.main()
    # Looks like winloop might be 3x faster than the Proctor Event Loop , THAT's A HUGE IMPROVEMENT!
    print("testing again but with winloop enabled")
    winloop.install()
    unittest.main()
```

The benchmarks for the code above are as follows

## Benchmarks

### TCP Connections
-------------------

| Asyncio Event Loop Policy         | Time (in Seconds)     |
|-----------------------------------|-----------------------|
| WinLoopPolicy                     | 0.493s                |
| WindowsProactorEventLoopPolicy    | 2.510s                |
| WindowsSelectorEventLoopPolicy    | 2.723s                |


That's a massive increase and jump from just TCP alone! I'll be posting more benchmarks soon, as
I modify more of the current test suites made by uvloop...


## How to Use Winloop with Fastapi

This was a cool little script I put together just to make Fastapi that much faster to handle:

```python

# TODO this code example is deprecated
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import winloop
import uvicorn
import asyncio
import datetime

app = FastAPI()

@app.on_event("startup")
def make_assertion():
    # Check to make sure that we bypassed the original eventloop Policy....
    assert isinstance(asyncio.get_event_loop_policy(), winloop.WinLoopPolicy)


@app.get("/test")
async def test_get_request():
    return HTMLResponse("<html><body><h1>FAST API WORKS WITH WINLOOP!</h1></body></html>")


# starllete will use asyncio.to_thread() so that this can remain asynchronous
@app.get("/date")
def test_dynamic_response():
    return str(datetime.datetime.now())


# Although tricky to pass and is not normal, it does in fact work...
if __name__ == "__main__":
    winloop.install()
    # Winloop's eventlooppolicy will be passed to uvicorn after this point...
    loop = asyncio.get_event_loop()
    config = uvicorn.Config(app=app,port=10000,loop=loop)
    server = uvicorn.Server(config)
    asyncio.run(server.serve())
```


## How To Use Winloop When Uvloop is not available

```python

# Here's A small Example of using winloop when uvloop is not available to us
import sys
import aiohttp
import asyncio

async def main():
    async with aiohttp.ClientSession("https://httpbin.org") as client:
        async with client.get("/ip") as resp:
            print(await resp.json())

if __name__ == "__main__":
    if sys.platform in ('win32', 'cygwin', 'cli'):
        from winloop import run
    else:
        # if we're on apple or linux do this instead
        from uvloop import run
    run(main())
  ```


 ## TODO-List
- [ ] In Winloop 0.2.0 or before 2026 I would like to start planning to migrate to pytest so that things could be formatted a little better. 
A Migration Python script might be needed or looked into. 

- [ ] Update Fastapi Example to a more recent version of fastapi

- [ ] Help Wanted. We're looking for other maintainers to help us.

- [x] Nightly Builds And Test Suite Workflows for anyone wanting to use newer unreleased versions. (Done, it runs now)

- [ ] Adding in the necessary hooks for pyinstaller to compile this fast library to executable code even though hooks have been known to inflate the size of the `.exe` files. This is because calling hidden-imports for all the `__init__.py` modules might annoy some developers. (Luckily I'm aware of this issue because I've been doing this myself...) [Update, This is now pending and I hope that it passes](https://github.com/pyinstaller/pyinstaller-hooks-contrib/pull/867) 

- [x] write a workflow for nightly builds if necessary for verification of pull requests.

- [ ] Update benchmarks (They are old) can't believe I maintained this project for over a year now...

## Videos
- By me: https://www.youtube.com/watch?v=tz9RYJ6aBZ8  (I might make a tutorial on how to use and install winloop it for those who have reading problems)
- My Presentation and Virtual Confrence: https://www.youtube.com/watch?v=Cbb6trkKWXY

## Contributing
I put my heart and soul into this library ever since it began and any help is apperciated and means a lot to me, I have other things I wish to explore so every little bit helps

### How Can I contribute?
- I make and branch and make edits and then I do a pull requests before I just step in and add something new.
This way you have time to review my additions, changes or feature beforehand.
- Forking The library.
- Fixing or editing workflows.
- Finding and editing spelling mistakes.
