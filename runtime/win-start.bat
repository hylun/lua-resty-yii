@echo off&title ����lua-resty-yii

rem ������ʾģʽ 
@mode con cols=100 lines=5000


set CMD_PATH=
for %%P in (%0) do set CMD_PATH=%%~dpP
cd /d "%CMD_PATH%"/../

set "pwd=%cd%"

if not exist runtime\logs md runtime\logs

start D:\openresty-1.11.2.2-win32\nginx -p  %pwd%\runtime -c  %pwd%\runtime\nginx.conf
