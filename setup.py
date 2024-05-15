from setuptools import Extension, setup, find_packages
import pathlib
import sys

from Cython.Build import cythonize


HERE = pathlib.Path("winloop")
_ROOT = pathlib.Path(__file__).parent


with open(str(_ROOT / 'winloop' / '_version.py')) as f:
    for line in f:
        if line.startswith('__version__ ='):
            _, _, version = line.partition('=')
            VERSION = version.strip(" \n'\"")
            break
    else:
        raise RuntimeError(
            'unable to read the version from winloop/_version.py')

# Temporary directory (For now) This will be mereged with vendor in a future update...
def get_c_files():
    path = pathlib.Path("winloop", "_vendor")

    def c_files(p:pathlib.Path):
        for i in p.iterdir():
            if i.is_dir():
                pass
            if i.name.endswith(".c"):
                yield i

    for c in c_files(path):
        yield c.as_posix()
    for c in c_files(path / "win"):
        yield c.as_posix()


# This is a temporary test Solution and is not the official file yet but this is to display/show what
# I'm currently using to compile the winloop library...
def do_installation():
    try:
        long_description = (HERE.parent / 'readme.md').open("r").read()
    except:
        long_description = ""

    # "Thank goodness we don't have to dig out the libpath ourselves I almost vomited" - Vizonex
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
            # For now (temporarily) we have 2 vendor directories. It is planned that _vendor will replace our current one in the future.
            include_dirs=["winloop/_vendor/src", "winloop/_vendor/win", "winloop/vendor/include", "winloop/_vendor" , "winloop/"],
            # NOTE uv_a.lib will be user-compiled when
            # I've fixed the install there's still been some problems with compiling fs-poll.c on it's own...
            extra_link_args=Windows_Libraries, # + ["winloop\\vendor\\libuv.lib"], testing...
            # I have some macros setup for now to help me with debugging - Vizonex
            library_dirs=["winloop"],
            define_macros=[
                ("_CRT_DECLARE_NONSTDC_NAMES", 0),
                ("WIN32_LEAN_AND_MEAN", 1),
                ('_GNU_SOURCE', 1),
                ('WIN32', 1),
                ("_WIN32_WINNT","0x0602")
            ],
            # Just in case, try optimizing a bit further....
            extra_compile_args=["/O2"]
        )
    ]


    setup(
        name="winloop",
        author="Vizonex",
        version=VERSION,
        description="""An alternative library for uvloop compatibility with Windows""",
        ext_modules=cythonize(ext),
        license="MIT",
        platforms=['Microsoft Windows'],
        keywords=[
            "winloop",
            "libuv",
            "windows",
            "cython",
            "fast-asyncio",
            "uvloop-alternative"
        ],
        # Credit to godlygeek for helping me fix the setup.py file
        packages=find_packages(include="winloop*"),

        include_package_data=True,
        long_description_content_type='text/markdown',
        long_description=long_description,
        classifiers=[
            'Programming Language :: Python :: 3.9',
            'Programming Language :: Python :: 3.10',
            'Programming Language :: Python :: 3.11',
            'Programming Language :: Python :: 3.12',
            'Intended Audience :: Developers',
            'Framework :: AsyncIO'
        ]
    )

if __name__ == "__main__":

    if sys.platform not in ('win32', 'cygwin', 'cli'):
        # TODO (Vizonex) Ask uvloop Owners/contributors if it would be ok or acceptable to recommend
        # this library as an alternative resource for any users on windows
        raise RuntimeError("Winloop is only available for Windows users. Please try installing uvloop instead, you won't be disappointed with it...")

    do_installation()



