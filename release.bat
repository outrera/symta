@echo off
rem creates release version folder under .\build\release\
xcopy .\lib .\build\release\lib /Y/I/E
xcopy .\pkg .\build\release\pkg /Y/I/E
xcopy .\runtime .\build\release\runtime /Y/I/E
xcopy .\src .\build\release\src /Y/I/E
xcopy .\tcc .\build\release\tcc /Y/I/E
copy /Y .\symta.exe .\build\release\symta.exe
copy /Y .\c.bat .\build\release\c.bat
copy /Y .\LICENSE .\build\release\LICENSE
copy /Y .\doc\readme.txt .\build\release\readme.txt
copy /Y .\doc\symta-by-example.md .\build\release\symta-by-example.md