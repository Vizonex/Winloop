![Alt text](https://raw.githubusercontent.com/Vizonex/Winloop/main/winloop.png)

# Winloop
An Alternative library for uvloop compatability with windows Because let's face it. Window's python asyncio can be garabage at times. 
I never really liked the fact that I couldn't make anything run faster escpecially when you have fiber internet connections in place. 
It always felt dissapointing when libuv is avalible on windows but doesn't have uvloop compatability. 
So I went ahead and downloaded the uvloop source code and modified the library to be windows compatable. 

"This library was inpired by the MagicStack Team and I take no credit for the original code and I had to modify." - Vizonex 

The differences with uvloop is that forking has been fully disabled and some smaller api calls had to be changed. Subprocesses instead release the gil instead of forking out although I might change that in the future. If handling asynchronous subprocesses becomes a problem to handle...


However there is a perfromance increase of about 5 times vs using the `WindowsSelectorEventLoopPolicy` and `WindowsProactorEventLoopPolicy` which has ssl problems in python 3.9. Winloop is a very good replacement for that as well.





## How to install Winloop on your windows OS 

```
pip install winloop
```

you can also clone the reposity and build the extension yourself by running if you wish to use/built the extension locally 

```
python setup.py build_ext --inplace 
```

This project is still in it's beta phase and may have some sneaky bugs that we didn't catch yet, so if you find find any bugs you can report them to our github repository.



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


That's a massive increase and jump from just TCP alone I'll be posting more benchmarks soon as 
I modify more of the current test suites made by uvloop...


## How to Use Winloop with Fastapi 

This was a cool little script I put together Just to make fastapi that much faster to handle

```python

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


## How To Use Winloop When Uvloop is not avalible

```python

# Here's A small Example of using winloop when uvloop is not avalible to us
import sys
import aiohttp
import asyncio 

async def main():
    async with aiohttp.ClientSession("https://httpbin.org") as client:
        async with client.get("/ip") as resp:
            print(await resp.json())

if __name__ == "__main__":
    if sys.platform in ('win32', 'cygwin', 'cli'):
        from winloop import install
    else:
        # if we're on apple or linux do this instead
        from uvloop import install 
    install()
    asyncio.run(main())
  ```

