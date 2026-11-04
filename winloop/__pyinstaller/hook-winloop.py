from PyInstaller.utils.hooks import collect_data_files

# XXX: pyinstaller contrib is very difficult so we have to make do with this.

hiddenimports = ["winloop._noop"]
datas = collect_data_files('winloop', excludes=['__pyinstaller']) # codespell:ignore datas
