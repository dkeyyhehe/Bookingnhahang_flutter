@echo off
echo Getting SHA-1 fingerprint for Google Sign-In...
echo.

REM Try to find keytool in common Java locations
set KEYTOOL_PATH=

REM Check JAVA_HOME
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        set KEYTOOL_PATH=%JAVA_HOME%\bin\keytool.exe
    )
)

REM Check Program Files
if "%KEYTOOL_PATH%"=="" (
    if exist "C:\Program Files\Java\jdk*\bin\keytool.exe" (
        for /d %%i in ("C:\Program Files\Java\jdk*") do set KEYTOOL_PATH=%%i\bin\keytool.exe
    )
)

REM Check Android Studio's JDK
if "%KEYTOOL_PATH%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe" (
        set KEYTOOL_PATH=%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe
    )
)

if "%KEYTOOL_PATH%"=="" (
    echo ERROR: keytool not found!
    echo.
    echo Please install Java JDK or use Android Studio's JDK.
    echo You can also run this command manually if you know where keytool is:
    echo.
    echo keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    echo.
    pause
    exit /b 1
)

echo Using keytool at: %KEYTOOL_PATH%
echo.
echo SHA-1 Fingerprint:
echo ----------------------------------------
"%KEYTOOL_PATH%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr /C:"SHA1:"
echo ----------------------------------------
echo.
echo Copy the SHA-1 value above and add it to Firebase Console:
echo 1. Go to Firebase Console > Project Settings > Your Apps
echo 2. Select your Android app (com.example.baitap)
echo 3. Click "Add fingerprint"
echo 4. Paste the SHA-1 value
echo 5. Download the new google-services.json
echo.
pause

