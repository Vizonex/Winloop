<img src="https://raw.githubusercontent.com/Vizonex/Winloop/main/winloop.png" width="200px"/>

[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
[![IDIM](https://raw.githubusercontent.com/Vizonex/IDIM-Badge/master/badge.svg)](https://github.com/Vizonex/IDIM-Badge)



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

## Testing with UV
The __uv__ package manager is the preferred method for testing __winloop__ and it's author uses `ruff` and `uv` by default.

```
uv venv
```

```shell
uv pip install winloop
```
If your bilding and testing it from your own fork the following should work.
```shell
uv pip install -e .
```
If your planning to setup.py build_ext commands
you will need to install setuptools and cython
```shell
uv pip install cython setuptools
```


## Reporting issues

If you find any bugs with this library be sure to open up an issue in the [issuetracker](https://github.com/Vizonex/Winloop/issues). The Winloop Contributors and the Owner when available will be happy try to help you figure out and diagnose your problems.


## How To Use Winloop When Uvloop is not available

```python
# Here's A small Example of using winloop when uvloop is not available to us
import sys
import aiohttp

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

Alternatively, There's another way to do this involving a smaller resource called `winuvloop` which combines both uvloop and winloop together.

```python
import aiohttp
import winuvloop

async def main():
    async with aiohttp.ClientSession("https://httpbin.org") as client:
        async with client.get("/ip") as resp:
            print(await resp.json())

if __name__ == "__main__":
    winuvloop.run(main())
```


## Videos
- By me: https://www.youtube.com/watch?v=tz9RYJ6aBZ8  (I might make a tutorial on how to use and install winloop it for those who have reading problems)

- My Presentation and Virtual Confrence Because I'm too busy to go to python conventions: https://www.youtube.com/watch?v=Cbb6trkKWXY


## Contributing
I put my heart and soul into this library ever since it began and any help is appreciated and means a lot to me, I have other things I wish to explore so every little bit helps. No matter what I go through in life, my heart is always here.

### How Can I contribute?
- Forking the library.
- Mirroring Winloop's improvements on uvloop's side.
- Reviewing pull requests.
- Fixing or editing workflows.
- Finding and editing spelling mistakes.
