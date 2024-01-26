from setuptools import Extension, setup, find_packages
import pathlib 
import sys 

from Cython.Build import cythonize



HERE = pathlib.Path("winloop")

__version__ = "0.1.2"



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

    ext = [
        Extension("winloop.loop",["winloop\\loop.pyx"], 
            # NOTE uv_a.lib will be user-compiled when 
            # I've fixed the install there's still been some probelms with compiling fs-poll.c on it's own...
            extra_link_args=Windows_Libraries + ["winloop\\vendor\\libuv.lib"],
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
            'Intended Audience :: Developers',
            'Framework :: AsyncIO'
        ],
        install_requires=["cython"]
    )

if __name__ == "__main__":

    if sys.platform not in ('win32', 'cygwin', 'cli'):
        # TODO (Vizonex) Ask uvloop Owners/contributors if it would be ok or acceptable to recommend 
        # this library as an alternative resource for any users on windows 
        raise RuntimeError("Winloop is only available for Windows users. Please try installing uvloop instead, you won't be disappointed with it...")

    do_installation()
    
    
 
