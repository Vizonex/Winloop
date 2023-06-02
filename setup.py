from setuptools import Extension, setup
from Cython.Build import cythonize
import pathlib 




# This is a temporary test Solution and is not the official file yet but this is to display/show what 
# I'm currently using to compile the winloop library...

current = pathlib.Path(__file__).parent / "winloop"
Winlib = pathlib.Path("C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.19041.0\\um\\x64")

ext = [
    Extension("winloop.loop",["winloop\\loop.pyx"],extra_link_args=[
        "winloop\\vendor\\uv_a.lib",
        str(Winlib / "Shell32.lib"),
        str(Winlib / "Ws2_32.lib"),
        str(Winlib / "Advapi32.lib"),
        str(Winlib / "iphlpapi.lib"),
        str(Winlib / "WSock32.lib"),
        str(Winlib / "Userenv.lib"),
        str(Winlib / "User32.lib")
        ],
        # I have some macros setup for now to help me with debugging - Vizonex
        library_dirs=["winloop"],define_macros=[('_GNU_SOURCE', 1),('WIN32', 1),("UVLOOP_DEBUG", 1)]
    )
]


setup(name="winloop.loop",ext_modules=cythonize(ext))
