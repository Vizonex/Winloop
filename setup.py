import sys

vi = sys.version_info
if vi < (3, 8):
    raise RuntimeError('winloop requires Python 3.8 or greater')

if sys.platform not in ('win32', 'cygwin', 'cli'):
    raise RuntimeError('winloop only supports Windows at the moment,'
                       ' install uvloop on Linux, MacOS, etc.')

from setuptools import Extension, setup, find_packages
import pathlib
import sys

from Cython.Build import cythonize


HERE = pathlib.Path("winloop")
_ROOT = pathlib.Path(__file__).parent


def get_c_files():
    path = pathlib.Path("vendor", "libuv", "src")

    def c_files(p: pathlib.Path):
        for i in p.iterdir():
            if i.is_dir():
                pass
            if i.name.endswith(".c"):
                yield i

    for c in c_files(path):
        yield c.as_posix()
    for c in c_files(path / "win"):
        yield c.as_posix()


# This is a temporary test solution and is not the official file yet but this
# is to display/show what I'm currently using to compile the winloop library...
try:
    long_description = (HERE.parent / 'readme.md').open("r").read()
except Exception:
    long_description = ""

# "Thank goodness we don't have to dig out the libpath ourselves I almost
# vomited" - Vizonex
Windows_Libraries = [
    "Shell32.lib",
    "Ws2_32.lib",
    "Advapi32.lib",
    "iphlpapi.lib",
    "WSock32.lib",
    "Userenv.lib",
    "User32.lib",
    "Dbghelp.lib",
    "Ole32.lib"
]

c_files = list(get_c_files())

ext = [
    Extension(
        "winloop.loop",
        ["winloop\\loop.pyx"] + c_files,
        include_dirs=["vendor/libuv/src", "vendor/libuv/src/win",
                      "vendor/libuv/include"],
        # NOTE uv_a.lib will be user-compiled when
        # I've fixed the install there's still been some problems with
        # compiling fs-poll.c on it's own...
        extra_link_args=Windows_Libraries,
        # I have some macros setup for now to help me
        # with debugging -Vizonex
        library_dirs=["winloop"],
        define_macros=[
            ("WIN32_LEAN_AND_MEAN", 1),
            ("_WIN32_WINNT", "0x0602")
        ]
    )
]

with open(str(_ROOT / 'winloop' / '_version.py')) as f:
    for line in f:
        if line.startswith('__version__ ='):
            _, _, version = line.partition('=')
            VERSION = version.strip(" \n'\"")
            break
    else:
        raise RuntimeError(
            'unable to read the version from winloop/_version.py')


setup(
    name="winloop",
    author="Vizonex",
    version=VERSION,
    description="Windows version of uvloop",
    ext_modules=cythonize(ext),
    keywords=[
        "winloop",
        "libuv",
        "windows",
        "fast-asyncio",
        "uvloop-alternative"
    ],
    # Credit to godlygeek for helping me fix the setup.py file
    packages=find_packages(include="winloop*"),
    include_package_data=True,
    long_description_content_type='text/markdown',
    long_description=long_description,
    classifiers=[
        'License :: OSI Approved :: Apache Software License',
        'License :: OSI Approved :: MIT License',
        'Operating System :: Microsoft :: Windows',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Intended Audience :: Developers',
        'Framework :: AsyncIO'
    ]
)
