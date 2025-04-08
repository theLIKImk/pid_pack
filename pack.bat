@echo off
set randomId=pack%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%
set Pack_ver=0.66.5

::IF NOT DEFINED PIDMD_ROOT echo.Wrong environment&exit /b

if exist "%~dp0_tmp" goto :pack

if not exist "%PIDMD_TMP%pack\_tmp" (
	mkdir "%PIDMD_TMP%pack\" >nul 2>NUL
	copy "%~dpnx0" "%PIDMD_TMP%pack\pack.bat" >nul 2>NUL
	copy "%~dp0unzip.exe" "%PIDMD_TMP%pack\unzip.exe" >nul 2>NUL
	echo.>"%PIDMD_TMP%pack\_tmp"
)
 
call "%PIDMD_TMP%pack\pack.bat" %*
goto end

:pack

if exist "%PIDMD_TMP%\pack-lock" echo.The package manager can only run one & exit /b
echo.>"%PIDMD_TMP%\pack-lock"

if /i "%1"=="/install" goto install
if /i "%1"=="/install-update" goto install
if /i "%1"=="/installed" goto installed
if /i "%1"=="/remove" goto remove
if /i "%1"=="/help" goto help
if /i "%1"=="/ver" goto ver

goto :end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:ver
	echo.%Pack_ver%
	goto end
	

:help
	echo Packmanager [TEST]
	echo.
	echo.pack.bat
	echo.  /help
	echo.  /install ^<path^> [/y]
	echo.  /install-update ^<path^> [/y]
	echo.  /installed
	echo.  /remove ^<package^> [/y]
	echo.  /ver
	echo.
	echo.Ver:%Pack_ver%
	goto end

:installed
	pushd %cd%
	cd /d "%PIDMD_SYS%\PACK\
	
	for /d %%i in (*) do (
		call :listinfo %%i
	)
	
	popd
	goto end
	
:listinfo
	call loadcfg ".\%1\info.INI"
	echo %1 (%version%): %info%
goto :eof


:remove
	set rm_item=%2
	
	if not exist "%PIDMD_SYS%\PACK\%rm_item%" echo Pack not exist! & goto end

	call loadcfg "%PIDMD_SYS%\PACK\%rm_item%\info.INI"
	echo.Pack: %pack% [%version%]
	echo.      %info%

	if /i "%3"=="/Y" goto :skip_rmact
	set /p rmact=Remove?[y/N]
	if /i not "%rmact%"=="y" echo Abort & goto end
	:skip_rmact
	
	pushd %cd%
	
	cd /d "%PIDMD_SYS%\PACK\%rm_item%\"
	echo Read filetree file......
	
	call logHE PACK INFO REOMVE#SP#%pack%#SP#PACK#SP#FILE
	if not exist filetree.ini (
		call logHE PACK ERRO [%pack%]Not#SP#find#SP#filetree.ini
		echo Not find filetree.ini file
		popd 
		goto end
	)
	
	SET _user=%PIDMD_USER%
	if exist "rmpack_cmd.bat" call rmpack_cmd.bat /int
	SET PIDMD_USER=%_user%
	
	FOR /F "delims=*" %%f in (filetree.ini) do (
		call :del %%f
	)
	if exist "rmpack_cmd.bat" call rmpack_cmd.bat /aft
	popd
	
	rd /s /q %PIDMD_SYS%\PACK\%rm_item%
	echo Done.
	goto :end


:del
	SET RM_PATH=%*
	SET RM_PATH=%RM_PATH:/=\%
	
	if "%RM_PATH:~-1%"=="\" goto :eof
	
	call logHE PACK INFO [%PACK%]REMOVE#SP#%PIDMD_ROOT: =#sp#%\%RM_PATH: =#sp#%
	
	echo Del - %PIDMD_ROOT%\%RM_PATH%
	del /f /s /q "%PIDMD_ROOT%\%RM_PATH%" >nul 2>nul
	rd  /s /q "%PIDMD_ROOT%\%RM_PATH%" >nul 2>nul
goto :eof

:install-n
	call loadcfg "%PIDMD_TMP%DATA.INI"
	echo.Package: %pack% [%version%]
	echo.         %info%
	echo.
	echo Pack Version:%version%
	call loadcfg "%PIDMD_SYS%PACK\%PACK%\INFO.INI"
	echo.@Installed Ver:%version%
	call loadcfg "%PIDMD_TMP%DATA.INI"
exit /b

:install-u
	call loadcfg "%PIDMD_TMP%DATA.INI"		
	echo.Package: %pack% [%version%]
	echo.         %info%
exit /b

:install 
	set packfile=%2
	
	if not exist "%2" echo Package file not exist! & goto end
	
	echo load info........
	"%~dp0unzip.exe" -t "%packfile%" >nul
	if "%errorlevel%"=="9" echo Package may be broken & goto :end
	
	"%~dp0unzip.exe" -o "%packfile%" data.ini -d "%PIDMD_TMP%\" -o >nul 2>nul
	"%~dp0unzip.exe" -o "%packfile%" ___data.ini -d "%PIDMD_TMP%\" -o >nul 2>nul
	REM if "%errorlevel%"=="11" echo Can not get package info & goto :end
	if exist "%PIDMD_TMP%___data.ini" (copy "%PIDMD_TMP%___data.ini" "%PIDMD_TMP%data.ini" >nul)
	if not exist "%PIDMD_TMP%data.ini" echo Can not get package info & goto :end
	
	echo load file tree........
	for /f "skip=3 tokens=1,2,3,* delims= " %%1 in ('unzip.exe -l "%packfile%"') do echo.%%4>>"%PIDMD_TMP%\%randomId%"

	if "%1"=="/install-update" (call :install-n) else (call :install-u)
	
	if /i "%3"=="/Y" goto :skip_inact
	set /p inact=Install?[y/N]
	if /i not "%inact%"=="y" echo Abort & goto end
	:skip_inact
	
	if /i not "%1"=="/install-update" if exist "%PIDMD_SYS%\PACK\%pack%" echo %pack% is installed & goto end
	
	call logHE PACK INFO INSTALL#SP#%pack%-%packfile: =#Sp#%
	
	"%~dp0unzip.exe" -o "%packfile%" ___unpack_cmd.bat -d "%PIDMD_TMP%\" -o >nul 2>nul
	if exist "%PIDMD_TMP%___unpack_cmd.bat" (call "%PIDMD_TMP%___unpack_cmd.bat" /int)
	
	echo Unpackage
	"%~dp0unzip.exe" -o "%packfile%" -d %PIDMD_ROOT% >nul
	if "%errorlevel%%"=="50" (
		echo.Unpack Error
		call logHE PACK ERRO Unpack#sp#Error:#SP#%packfile: =#Sp#%
		goto end
	)
	
	SET _user=%PIDMD_USER%
	if exist "%PIDMD_ROOT%___unpack_cmd.bat" call "%PIDMD_ROOT%___unpack_cmd.bat" /aft
	SET PIDMD_USER=%_user%
	
	echo Copying package file tree
	IF NOT EXIST "%PIDMD_SYS%\PACK\%pack%" mkdir "%PIDMD_SYS%\PACK\%pack%"
	call logHE PACK INFO SET#SP#%pack%
	
	IF NOT EXIST "%PIDMD_SYS%\PACK\%pack%\filetree.ini" copy "%PIDMD_TMP%\%randomId%" "%PIDMD_SYS%\PACK\%pack%\filetree.ini" >nul
	copy "%PIDMD_TMP%DATA.INI" "%PIDMD_SYS%PACK\%pack%\info.ini" >nul
	copy "%PIDMD_TMP%___DATA.INI" "%PIDMD_SYS%PACK\%pack%\info.ini" >nul
	if exist "%PIDMD_ROOT%___rmpack_cmd.bat" copy "%PIDMD_ROOT%___rmpack_cmd.bat" "%PIDMD_SYS%PACK\%pack%\rmpack_cmd.bat" >nul
	del /f /s /q "%PIDMD_ROOT%\data.ini" >nul 2>nul
	del /f /s /q "%PIDMD_ROOT%\___data.ini" >nul 2>nul
	del /f /s /q "%PIDMD_ROOT%\___unpack_cmd.bat" >nul 2>nul
	del /f /s /q "%PIDMD_ROOT%\___rmpack_cmd.bat" >nul 2>nul

	echo Done
	goto end

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:end
	set pack=
	set version=
	set info=
	del "%PIDMD_TMP%\%randomId%" >nul  2>nul
	del "%PIDMD_TMP%\DATA.INI" >nul  2>nul
	del "%PIDMD_TMP%\___DATA.INI" >nul  2>nul
	del "%PIDMD_TMP%\pack-lock" >nul  2>nul
	del "%PIDMD_TMP%\pack\_tmp" >nul  2>nul
	exit /b
