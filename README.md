**1. Необхідне ПО**

-Python<br>
-Docker Desktop/Engine (Linux)
<br><br>

**2. Встановлення Docker Desktop/Engine**
 
*2.1 (Windows/MacOS)*<br>
-Скачайте інсталятор, що підходить вашій ОС, з офіційного сайту Docker:&nbsp;https://www.docker.com/<br>
-Перевірте ввімкнення віртуалізації (Virtualization) у параметрах BIOS/UEFI вашого комп'ютера<br>
-Запустіть файл.exe та дотримуйтесь інструкцій, обравши обов'язкове використання компонентів WSL 2.

*2.2 (Linux)*<br>
-Відкрийте Terminal (Ctrl + Alt + T) та встановіть офіційний пакет Docker Engine:
```
sudo apt update
sudo apt install docker.io docker-compose-v2 -y
```
-Надайте права користувачу керувати контейнерами без sudo:
```
sudo usermod -aG docker $USER
```
-Перезайдіть у систему, щоб застосувати надані права:

-Щоб перевірити, чи успішно встановлений Docker Engine, виконайте:
```
sudo docker run hello-world
```
<br>

**3. Структура робочої папки 'expenses'**

-*.venv*: файли віртуального оточення (з'являються під час створення)<br>
&emsp;-Include,<br>
&emsp;-Lib,<br>
&emsp;-Scripts (for Windows) / bin (for MacOS),<br> 
&emsp;-share (for MacOS, Linux),<br> 
&emsp;-pyvenv.cfg<br>
-*data*: робочі файли<br>
&emsp;-csv: містить файли отримані у результаті виконання коду<br>
&emsp;-jupyter: частина проекту, що була виконана у Jupyter Notebook<br>
&emsp;-power bi: частина проекту, що була виконана у Power BI<br>
&emsp;-python: містить файл отриманий у результаті конвертування jupyter-скрипта<br>
&emsp;-sql: частина проекту, що була виконана у базі PostgreSQL<br>
&emsp;-workbooks: вхідні файли Excel<br>
-*.env.example*: приклад-шаблон для збереження конф. даних<br>
-*.gitignore*: перлік файлів які НЕ потрібно публікувати<br>
-*l_start.sh*: linux-файл автоматичної підготовки середовища для запуску основного коду<br>
-*m_start.sh*: macos-файл автоматичної підготовки середовища для запуску основного коду<br>
-*main.py*: основний код<br>
-*requirements.txt*: залежності (необхідні пакети) для виконання коду<br>
-*w_start.cmd*: windows-файл автоматичної підготовки середовища для запуску основного коду
<br><br>

**3. Швидкий запуск у Windows (Command Prompt)**

3.1 Відкрити Command Prompt:
```
комбінація Win+R та Enter
```
3.2 Створити нову базу даних PostgreSQL у Docker Desktop (без volume):

-УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses ^
           -p 5432:5432 ^
           -e POSTGRES_USER=expenses ^
           -e POSTGRES_DB=expenses ^
           -e POSTGRES_PASSWORD=mysecretpassword ^
           postgres:18.4
```
3.3 Перейти до робочої папки 'expenses':
```
cd шлях\до\директорії\expenses
```
3.4 Скопіювати файл '.env.example' та дати йому назву '.env':
```
copy .env.example .env
```
3.5 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
notepad .env
```
3.6 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Ctrl + S для збереження, потім закрити вікно
```
3.7 Скористатися автоматичною підготовкою середовища для виконання проекту:
```
.\w_start.cmd
```
3.8 Після завершення попередньго етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**4. Повний запуск у Windows (Command Prompt)**

4.1-4.6 відповідають пунктам: 3.1-3.6 з попереднього розділу

4.7 Створити нове віртуальне оточення:
```
python -m venv .venv --without-scm-ignore-files
```
4.8 Активувати віртуальне оточення:
```
.venv\scripts\activate
```
4.9 Оновити менеджер пакетів pip до останньої версії:
```
python.exe -m pip install --upgrade pip
```
4.10 Встановити потрібні бібліотеки:
```
pip3 install -r requirements.txt
```
4.11 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
4.12 Ознайомитися з додатковими параметрами запуску тіла програми:
```
python main.py -h
```
4.13 Запустити програму:
```
python main.py
```
<br>

**5. Швидкий запуск у MacOS (Terminal)**

5.1 Відкрити додаток Terminal:
``` 
Cmd + Space та введіть "Terminal"
```
5.2 Створити нову базу даних PostgreSQL у Docker Desktop (без volume):

-УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses \
           -p 5432:5432 \
           -e POSTGRES_USER=expenses \
           -e POSTGRES_DB=expenses \
           -e POSTGRES_PASSWORD=mysecretpassword \
           postgres:18.4
```
5.3 Перейти до робочої папки 'expenses':
```
cd ~/шлях/до/директорії/expenses
```
5.4 Скопіювати файл '.env.example' та дати йому назву '.env':
```
cp .env.example .env
```
5.5 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
nano .env
```
5.6 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Control + X, потім Y (Yes), а тоді Return
```
5.7 Надати файлу попередньої підготовки дозвіл на виконання:
```
chmod +x m_start.sh
```
5.8 Скористатися автоматичною підготовкою середовища для виконання проекту:
```
source m_start.sh
```
5.9 Після завершення попереднього етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**6. Повний запуск у MacOS (Terminal)**

6.1-6.6 відповідають пунктам: 5.1-5.6 з попереднього розділу

6.7 Створити нове віртуальне оточення:
```
python3 -m venv .venv --without-scm-ignore-files
```
6.8 Активувати створене середовище:
```
source .venv/bin/activate
```
6.9 Оновити менеджер пакетів pip до останньої версії:
```
python3 -m pip install --upgrade pip
```
6.10 Встановити потрібні бібліотеки:
```
pip3 install -r requirements.txt
```
6.11 Встановити модуль для відображеня візуалізацій:
``` 
brew install python-tk
```
6.12 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
6.13 Ознайомитися з додатковими параметрами запуску тіла програми:
```
python main.py -h
```
6.14 Запустити програму:
```
python main.py
```
<br>

**7. Швидкий запуск у Linux (Terminal)**

7.1 Відкрити додаток Terminal:
``` 
комбінація Ctrl + Alt + T
```
7.2 Створити нову базу даних PostgreSQL у Docker Engine (без volume):

-УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses \
           -p 5432:5432 \
           -e POSTGRES_USER=expenses \
           -e POSTGRES_DB=expenses \
           -e POSTGRES_PASSWORD=mysecretpassword \
           postgres:18.4
```
7.3 Здійснити запуск створеної бази:
```
docker start postgres-expenses
```
7.4 Перейти до робочої папки 'expenses':
```
cd Downloads/expenses
```
7.5 Скопіювати файл '.env.example' та дати йому назву '.env':
```
cp .env.example .env
```
7.6 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
nano .env
```
7.7 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Ctrl + X, потім Y (Yes), а тоді Enter
```
7.8 Надати файлу попередньої підготовки дозвіл на виконання:
```
chmod +x l_start.sh
```
7.9 Скористатися автоматичною підготовкою середовища для виконання проекту:
```
source l_start.sh
```
7.10 Після завершення попереднього етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**8. Повний запуск у Linux (Terminal)**

8.1-8.7 відповідають пунктам: 7.1-7.7 з попереднього розділу

8.8 Встановити модуль ізольованих віртуальних оточень:
```
sudo apt update
apt install python3.12-venv
```
8.9 Створити нове віртуальне оточення:
```
python3 -m venv .venv
```
8.10 Активувати створене середовище:
```
source .venv/bin/activate
```
8.11 Оновити менеджер пакетів pip до останньої версії:
```
python -m pip install --upgrade pip
```
8.12 Встановити потрібні бібліотеки:
```
pip install -r requirements.txt
```
8.13 Встановити модуль для відображеня візуалізацій:
```
sudo apt install -y python3-tk
```
8.14 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
8.15 Ознайомитися з додатковими параметрами запуску тіла програми:
```
python main.py -h
```
8.16 Запустити програму:
```
python main.py
```