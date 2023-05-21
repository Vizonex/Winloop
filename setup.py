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
        str(Winlib / "Ws2_32.lib"),
        str(Winlib / "Advapi32.lib"),
        str(Winlib / "iphlpapi.lib"),
        str(Winlib / "WSock32.lib"),
        str(Winlib / "Userenv.lib"),
        str(Winlib / "User32.lib")
        ],
        library_dirs=["winloop"]
    )
]


setup(name="winloop.loop",ext_modules=cythonize(ext))