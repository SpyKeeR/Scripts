@echo off 

cd /d "C:\Users\SpyKeeR\Magazines"

set "_jpeg2pdf="C:\Users\SpyKeeR\jpeg2pdf.exe""
set "_jpeg2pdf=%_jpeg2pdf% -p A4 -n auto -z fw -c spykeer .\*.jpg -o"

for /r /d %%i in (*)do chDir /d "%%~dpnxi" && =;(
     @%_jpeg2pdf% ".\%%~nxi.pdf" | find /i ".pdf"
     if exist ".\\%%~nxi.pdf" 2>nul del ".\*.jpg"
    );=

"%__AppDir__%tree.com" /f /a "%~dp0" | "%__AppDir__%more.com"