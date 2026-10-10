# Recommended Extensions for editing winloop

If you want all the nitty gritties about vscode extensions the owner is using the [vscode-cython](https://marketplace.visualstudio.com/items?itemName=ktnrg45.vscode-cython) is strongly recommended although deprecated and no longer being maintained, when working with C++ Extensions the [Microsoft C++ Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) does the job. However for any open-source and privacy enthusiests another extension might be better than this one.


## Common Problems

### How do I to ensure `Python.h` is registered?

If you get a message such as `cannot open source file "Python.h"` Don't be alarmed. It's because it's not registered to be visible. The way you fix this is in the `VS Code Microsoft C++ Extension` is rather easy.  A Configuration that adds the __PYTHONPATH__ Environment variable you made when you setup your first installation of python should automatically do the job.

Example configuration file would be `.vscode/c_cpp_properties.json`
```json
{
    "configurations": [
        {
            "name": "Win32",
            "includePath": [
                "${workspaceFolder}/**",
                "${PYTHONPATH}/**"
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE"
            ],
            "windowsSdkVersion": "10.0.19041.0",
            "compilerPath": "cl.exe",
            "cStandard": "c17",
            "cppStandard": "c++17",
            "intelliSenseMode": "windows-msvc-x64"
        }
    ],
    "version": 4
}
```

After that, `Python.h` should be within reach, problem solved.
