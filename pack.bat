@echo off
set randomId=pack%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%%random:~0,1%
set Pack_ver=0.71.2

IF NOT DEFINED PIDMD_ROOT echo.Wrong environment&exit /b

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
	echo.Package: %pack% [%version%]
	echo.Author:  %author%
	echo.         %info%
	echo.
	echo.Depend:  %depend%
	echo.

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
	
	REM 依赖检测
	call log PACK INFO Check#sp#depends
	if not exist "%PIDMD_SYS%\PACK\%rm_item%\DEPEND" goto :_skip_depend_check
	for /f "delims=*" %%d in ('dir /B ^"%PIDMD_SYS%\PACK\%rm_item%\DEPEND\^"') do set PACK_REMOVE_CHECK_DEPENDS=%%d
	echo.[%PACK_REMOVE_CHECK_DEPENDS%]
	if defined PACK_REMOVE_CHECK_DEPENDS (
		call log PACK ERRO There#SP#are#SP#packages#SP#that#SP#depend#SP#on#SP#this,#SP#and#SP#they#SP#cannot#SP#be#SP#removed
		echo.
		echo List:
		dir /B "%PIDMD_SYS%\PACK\%rm_item%\DEPEND\"
		popd
		goto :end
	)
	:_skip_depend_check
	
	REM 依赖标识移除
	if not exist "%PIDMD_SYS%\PACK\%rm_item%\USE" goto :_skip_pack_use_check
	for /f "delims=*" %%d in ('dir /B ^"%PIDMD_SYS%\PACK\%rm_item%\USE\^"') do set PACK_REMOVE_USE_TAG=%%d
	echo.[%PACK_REMOVE_USE_TAG%]
	if not defined PACK_REMOVE_USE_TAG goto :_skip_pack_use_check
	for /f "delims=*" %%d in ('dir /B ^"%PIDMD_SYS%\PACK\%rm_item%\USE\^"') do DEL /F /S /Q "%PIDMD_SYS%\PACK\%%d\DEPEND\%rm_item%">nul
	:_skip_pack_use_check
	
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
	set pack_update_ver1=%version%
	echo.Package: %pack% [%version%]
	echo.Author:  %author%
	echo.         %info%
	echo.
	echo    - Pack Version:%version%
	call loadcfg "%PIDMD_SYS%PACK\%PACK%\INFO.INI"
	echo.   - Installed Ver:%version%
	set pack_update_ver2=%version%
	call loadcfg "%PIDMD_TMP%DATA.INI"
	echo.
	echo.Depend:  %depend%
exit /b

:install-u
	call loadcfg "%PIDMD_TMP%DATA.INI"		
	echo.Package: %pack% [%version%]
	echo.Author:  %author%
	echo.         %info%
	echo.
	echo.Depend:  %depend%
exit /b

:install-depend_true
	set pack_install_depend=true
	set pack_install_depend_list=%pack_install_depend_list%,%pack%
exit /b

:install-depend_false
	echo Pack %_pack% need version is %_Ver1%, but it is %version%
	set pack_install_depend=false
exit /b

:install-check_depend_version_//_check
	if "%_Ver1:~2%"=="%version%" call :install-depend_true & exit /b
	call :install-depend_false & exit /b
	
:install-check_depend_version_gtr_check
	call cprver.cmd %_Ver1:~2% %version%
	if "%errorlevel%"=="2" call :install-depend_true & exit /b
	call :install-depend_false & exit /b
	
:install-check_depend_version_geq_check
	if "%_Ver1:~2%"=="%version%" call :install-depend_true & exit /b
	call cprver.cmd %_Ver1:~2% %version%
	if "%errorlevel%"=="2" call :install-depend_true & exit /b
	call :install-depend_false & exit /b
		
:install-check_depend_version_--_check
	call cprver.cmd %_Ver1:~2% %version%
	if "%errorlevel%"=="1" call :install-depend_true & exit /b
	call :install-depend_false & exit /b
		
:install-check_depend_version_-/check
	if "%_Ver1:~2%"=="%version%" call :install-depend_true & exit /b
	call cprver.cmd %_Ver1:~2% %version%
	if "%errorlevel%"=="1" call :install-depend_true & exit /b
	call :install-depend_false & exit /b
		
:install-check_depend_version
	set _Ver1=%1
	set _pack=%2
	call loadcfg "%PIDMD_SYS%PACK\%2\info.ini"

	REM 版本判断
	if "%_Ver1:~0,2%"=="//" call :install-check_depend_version_//_check & exit /b
	if "%_Ver1:~0,2%"=="++" call :install-check_depend_version_grt_check & exit /b
	if "%_Ver1:~0,2%"=="+/" call :install-check_depend_version_geq_check & exit /b
	if "%_Ver1:~0,2%"=="--" call :install-check_depend_version_--_check & exit /b
	if "%_Ver1:~0,2%"=="-/" call :install-check_depend_version_-/_check & exit /b
	if "%_Ver1:~0,2%"=="$$" call :install-depend_true & exit /b
	if "%_Ver1%"=="$$" call :install-depend_true & exit /b
	if "%_Ver1%"=="%version%" call :install-depend_true & exit /b
	call :install-depend_false & exit /b

:install-check_depend
	for %%d in (%depend%) do (
		for /f "tokens=1,2 delims=:" %%p in ("%%d") do (
			if not exist "%PIDMD_SYS%PACK\%%p" echo Not Found pack %%p-%%q,Abort & exit /b 1
			call :install-check_depend_version %%q %%p
		)
	)
exit /b 0

:install-update_check
	if not defined pack_update_ver1 echo Version error & exit /b 1
	if not defined pack_update_ver2 echo Version error & exit /b 1
	call cprver.cmd %pack_update_ver1% %pack_update_ver2%
	if "%errorlevel%"=="2" echo The version cannot be downgraded & exit /b 1
exit /b 0

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
	
	rem 区别显示
	if "%1"=="/install-update" (call :install-n) else (call :install-u)
	
	REM 更新版本检测
	if "%1"=="/install-update" call :install-update_check
	if "%errorlevel%"=="1" goto :end
	
	REM 依赖
	call :install-check_depend
	if "%errorlevel%"=="1" echo Abort & goto :end
	if "%pack_install_depend%"=="false" echo Abort & goto :end
	call loadcfg "%PIDMD_TMP%DATA.INI"
	
	REM 操作确认
	if /i "%3"=="/Y" goto :skip_inact
	set /p inact=Install?[y/N]
	if /i not "%inact%"=="y" echo Abort & goto end
	:skip_inact
	
	if /i not "%1"=="/install-update" if exist "%PIDMD_SYS%\PACK\%pack%" echo %pack% is installed & goto end
	
	REM 安装处理
	call logHE PACK INFO INSTALL#SP#%pack%-%packfile: =#Sp#%
	
	REM 脚本
	"%~dp0unzip.exe" -o "%packfile%" ___unpack_cmd.bat -d "%PIDMD_TMP%\" -o >nul 2>nul
	if exist "%PIDMD_TMP%___unpack_cmd.bat" (call "%PIDMD_TMP%___unpack_cmd.bat" /int)
	
	REM 解压
	echo Unpackage
	"%~dp0unzip.exe" -o "%packfile%" -d %PIDMD_ROOT% >nul
	if "%errorlevel%%"=="50" (
		echo.Unpack Error
		call logHE PACK ERRO Unpack#sp#Error:#SP#%packfile: =#Sp#%
		goto end
	)
	
	REM 脚本
	SET _user=%PIDMD_USER%
	if exist "%PIDMD_ROOT%___unpack_cmd.bat" call "%PIDMD_ROOT%___unpack_cmd.bat" /aft
	SET PIDMD_USER=%_user%
	
	REM 复制信息文件
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
	
	REM 依赖
	call log PACK INFO SET#SP#%pack%#SP#DEPEND
	for %%d in (%pack_install_depend_list%) do (
		if not exist "%PIDMD_SYS%PACK\%%d\DEPEND" mkdir "%PIDMD_SYS%PACK\%%d\DEPEND"
		if not exist "%PIDMD_SYS%PACK\%pack%\USE" mkdir "%PIDMD_SYS%PACK\%pack%\USE"
		echo.>"%PIDMD_SYS%PACK\%%d\DEPEND\%pack%"
		echo.>"%PIDMD_SYS%PACK\%pack%\USE\%%d"
	)

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
	set depend=
	set author=
	set pack_install_depend=true
	set pack_install_depend_list=
	set PACK_REMOVE_USE_TAG=
	set PACK_REMOVE_CHECK_DEPENDS=
	del "%PIDMD_TMP%\%randomId%" >nul  2>nul
	del "%PIDMD_TMP%\DATA.INI" >nul  2>nul
	del "%PIDMD_TMP%\___DATA.INI" >nul  2>nul
	del "%PIDMD_TMP%\pack-lock" >nul  2>nul
	del "%PIDMD_TMP%\pack\_tmp" >nul  2>nul
	exit /b
