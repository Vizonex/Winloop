from setuptools import Extension, setup
import pathlib 
import sys 
try:
    from Cython.Build import cythonize
except:
    print("please install cython first")
    sys.exit(1)



HERE = pathlib.Path("winloop")
long_description = open('readme.md').read()

__version__ = "0.0.1"



# This is a temporary test Solution and is not the official file yet but this is to display/show what 
# I'm currently using to compile the winloop library...
def do_installation():


    # "Thank goodness we don't have to dig out the libpath ourselves I almost vomited" - Vizonex            
    Windows_Libraries = [
        "Shell32.lib",
        "Ws2_32.lib",
        "Advapi32.lib",
        "iphlpapi.lib",
        "WSock32.lib",
        "Userenv.lib",
        "User32.lib"
    ]

    ext = [
        Extension("winloop.loop",["winloop\\loop.pyx"], 
            # NOTE uv_a.lib will be user-compiled when 
            # I've fixed the install there's still been some probelms with compiling fs-poll.c on it's own...
            extra_link_args=Windows_Libraries + ["winloop\\vendor\\uv_a.lib"],
            # I have some macros setup for now to help me with debugging - Vizonex
            library_dirs=["winloop"],
            define_macros=[
                ('_GNU_SOURCE', 1),
                ('WIN32', 1),
                ("_WIN32_WINNT","0x0602")
            ],
            # Just incase, Try Optimzing a bit further....
            extra_compile_args=["/O2"]
        )
    ]


    setup(
        name="winloop",
        author="Vizonex",
        version=__version__,
        description="""An Alternative library for uvloop compatability with windows""",
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
        long_description_content_type='text/markdown',
        long_description=long_description,
        classifiers=[
            'Programming Language :: Python :: 3.9',
            'Programming Language :: Python :: 3.10',
            'Programming Language :: Python :: 3.11',
            'Intended Audience :: Developers',
            'Framework :: AsyncIO'
        ],
        install_requires=["cython"]
    )

if __name__ == "__main__":

    if sys.platform not in ('win32', 'cygwin', 'cli'):
        # TODO (Vizonex) Ask uvloop Owners/contributors if it would be ok or acceptable to recommend 
        # this library as an alternative resource for any users on windows 
        raise RuntimeError("Winloop is Only Avalible for Windows Users Please try installing uvloop instead, you won't be dissapointed with it...")

    do_installation()
    
 
