@echo off
echo.
echo **************
echo * ПІДГОТОВКА *
echo **************
echo.
echo 1. Створюю нове віртуальне оточення...
python -m venv .venv --without-scm-ignore-files
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Не вдалося створити віртуальне середовище!
    pause
    exit /b %errorlevel%
)
echo.
echo Віртуальне оточення створено успішно.
echo.
echo 2. Активую створене середовище...
call .venv\scripts\activate.bat
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Не вдалося активувати Віртуальне середовище!
    pause
    exit /b %errorlevel%
)
echo.
echo Віртуальне середовище активовано.
echo.
echo 3. Оновлюю менеджер пакетів pip до останньої версії...
python.exe -m pip install --upgrade pip
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Не вдалося встановити останню версію менеджера пакетів!
    pause
    exit /b %errorlevel%
)
echo.
echo Менеджер пакетів оновлено до останньої версії.
echo.
echo 4. Встановлюю туди необхідні бібліотеки...
pip3 install -r requirements.txt
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Не вдалося встановити необхідні пакети!
    pause
    exit /b %errorlevel%
)
echo.
echo Всі потрібні модулі було встановлено.
echo.
echo 5. Форматую скрипт 'main.py' згідно до стандартів PEP8...
black main.py
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Не знайдено файл 'main.py' або не вдалося його форматувати!
    pause
    exit /b %errorlevel%
)
echo.
echo Cкрипт 'main.py' було приведено до стандартів PEP8 успішно.
echo.
echo.
echo ******************
echo * ЗАПУСК ПРОЕКТУ *
echo ******************
echo.
echo 1. Для аналізу даних за весь період (01.2013 – 04.2017), введіть: 
echo    python main.py
echo.
echo 2 Ознайомлення з додатковими параметрами запуску: 
echo   python main.py -h 
echo.