**1. Необхідне ПЗ**

- Python<br>
- Docker Desktop (Windows/MacOS)
- Docker Engine (Linux)
<br><br>

**2. Встановлення Python**

*2.1 (Windows/MacOS)*<br>
- Скачайте інсталятор, для вашоїй ОС (file.exe-windows, file.pkg-macos), з офіційного сайту:&nbsp;https://www.python.org/<br>
- За наявності поставте галочку "Add python.exe to PATH" у нижній частині вікна<br>
- Запустіть інсталятор та дотримуйтесь інструкцій<br>
- Відкрийте cmd або terminal та перевірте успішність встановлення:
```
python --version
```

*2.2 (Linux)*<br>
- У більшості дистрибутивів Linux Python вже встановлено або він доступний через стандартний менеджер пакетів

- Для Ubuntu або Debian відкрийте terminal та оновіть список пакетів командою:
``` 
sudo apt update
```
- Встановіть Python за допомогою:
```
sudo apt install python3
```
- Для Fedora або CentOS використовуйте команду:
```
sudo dnf install python3
```
- Перевірте успішність встановлення командою:
```
python3 --version
```
<br>

**3. Встановлення Docker Desktop/Engine**
 
*3.1 (Windows/MacOS)*<br>
- Скачайте інсталятор, для вашоїй ОС (file.exe-windows, file.pkg-macos), з офіційного сайту:&nbsp;https://www.docker.com/<br>
- Перевірте ввімкнення віртуалізації (Virtualization) у параметрах BIOS/UEFI вашого комп'ютера<br>
- Запустіть інсталятор та дотримуйтесь інструкцій, обравши обов'язкове використання компонентів WSL 2.

*3.2 (Linux)*<br>
- Відкрийте Terminal (Ctrl + Alt + T) та встановіть офіційний пакет Docker Engine:
```
sudo apt update
sudo apt install docker.io docker-compose-v2 -y
```
- Надайте права користувачу керувати контейнерами без sudo:
```
sudo usermod -aG docker $USER
```
- Перезайдіть у систему, щоб застосувати надані права:

- Щоб перевірити, чи успішно встановлений Docker Engine, виконайте:
```
sudo docker run hello-world
```
<br>

**4. Швидкий запуск у Windows (Command Prompt)**

4.1 Відкрити Command Prompt:
```
комбінація Win+R та Enter
```
4.2 Створити нову базу даних PostgreSQL у Docker Desktop (без volume):

- УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses ^
           -p 5432:5432 ^
           -e POSTGRES_USER=expenses ^
           -e POSTGRES_DB=expenses ^
           -e POSTGRES_PASSWORD=mysecretpassword ^
           postgres:18.4
```
4.3 Перейти до завантаженої директорії 'personal_finance_analysis':
```
cd шлях\до\personal_finance_analysis
```
4.4 Скопіювати файл '.env.example' та дати йому назву '.env':
```
copy .env.example .env
```
4.5 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
notepad .env
```
4.6 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Ctrl + S для збереження, потім закрити вікно
```
4.7 Скористатися автоматичною підготовкою середовища для виконання проєкту:
```
.\w_start.cmd
```
4.8 Після завершення попередньго етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**5. Повний запуск у Windows (Command Prompt)**

5.1-5.6 відповідають пунктам: 4.1-4.6 з попереднього розділу

5.7 Створити нове віртуальне оточення (.venv):
```
python -m venv .venv --without-scm-ignore-files
```
5.8 Активувати створене середовище:
```
.venv\scripts\activate
```
5.9 Оновити менеджер пакетів pip до останньої версії:
```
python.exe -m pip install --upgrade pip
```
5.10 Встановити потрібні бібліотеки:
```
pip3 install -r requirements.txt
```
5.11 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
5.12 Для аналізу даних за весь період (01.2013 – 04.2017), введіть:
```
python main.py
```
5.13 Ознайомитися з додатковими параметрами запуску проєкту:
```
python main.py -h
```
<br>

**6. Швидкий запуск у MacOS (Terminal)**

6.1 Відкрити додаток Terminal:
``` 
Cmd + Space та введіть "Terminal"
```
6.2 Створити нову базу даних PostgreSQL у Docker Desktop (без volume):

- УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses \
           -p 5432:5432 \
           -e POSTGRES_USER=expenses \
           -e POSTGRES_DB=expenses \
           -e POSTGRES_PASSWORD=mysecretpassword \
           postgres:18.4
```
6.3 Перейти до завантаженої директорії 'personal_finance_analysis':
```
cd ~/шлях/до/personal_finance_analysis
```
6.4 Скопіювати файл '.env.example' та дати йому назву '.env':
```
cp .env.example .env
```
6.5 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
nano .env
```
6.6 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Control + X, потім Y (Yes), а тоді Return
```
6.7 Надати файлу попередньої підготовки дозвіл на виконання:
```
chmod +x m_start.sh
```
6.8 Скористатися автоматичною підготовкою середовища для виконання проєкту:
```
source m_start.sh
```
6.9 Після завершення попереднього етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**7. Повний запуск у MacOS (Terminal)**

7.1-7.6 відповідають пунктам: 6.1-6.6 з попереднього розділу

7.7 Створити нове віртуальне оточення (.venv):
```
python3 -m venv .venv --without-scm-ignore-files
```
7.8 Активувати створене середовище:
```
source .venv/bin/activate
```
7.9 Оновити менеджер пакетів pip до останньої версії:
```
python3 -m pip install --upgrade pip
```
7.10 Встановити потрібні бібліотеки:
```
pip3 install -r requirements.txt
```
7.11 Встановити модуль для відображеня візуалізацій:
``` 
brew install python-tk
```
7.12 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
7.13 Для аналізу даних за весь період (01.2013 – 04.2017), введіть:
```
python main.py
```
7.14 Ознайомитися з додатковими параметрами запуску проєкту:
```
python main.py -h
```
<br>

**8. Швидкий запуск у Linux (Terminal)**

8.1 Відкрити додаток Terminal:
``` 
комбінація Ctrl + Alt + T
```
8.2 Створити нову базу даних PostgreSQL у Docker Engine (без volume):

- УВАГА: впевніться, що порт 5432 не зайнятий іншим процесом, або використайте інший вільний порт!
```
docker run -d --name postgres-expenses \
           -p 5432:5432 \
           -e POSTGRES_USER=expenses \
           -e POSTGRES_DB=expenses \
           -e POSTGRES_PASSWORD=mysecretpassword \
           postgres:18.4
```
8.3 Здійснити запуск створеної бази:
```
docker start postgres-expenses
```
8.4 Перейти до завантаженої директорії 'personal_finance_analysis':
```
cd шлях/до/personal_finance_analysis
```
8.5 Скопіювати файл '.env.example' та дати йому назву '.env':
```
cp .env.example .env
```
8.6 Відкрити '.env' та змінити значення на ті, що необхідні для з'єднання з базою PostgreSQL:
```
nano .env
```
8.7 Зберегти відкорегований файл конфігурацій та вийти:
```
комбінація Ctrl + X, потім Y (Yes), а тоді Enter
```
8.8 Надати файлу попередньої підготовки дозвіл на виконання:
```
chmod +x l_start.sh
```
8.9 Скористатися автоматичною підготовкою середовища для виконання проєкту:
```
source l_start.sh
```
8.10 Після завершення попереднього етапу здійснити запуск основного коду, дотримуючись інструкцій на екрані.
<br><br>

**9. Повний запуск у Linux (Terminal)**

9.1-9.7 відповідають пунктам: 8.1-8.7 з попереднього розділу

9.8 Встановити модуль ізольованих віртуальних оточень:
```
sudo apt update
apt install python3.12-venv
```
9.9 Створити нове віртуальне оточення (.venv):
```
python3 -m venv .venv
```
9.10 Активувати створене середовище:
```
source .venv/bin/activate
```
9.11 Оновити менеджер пакетів pip до останньої версії:
```
python -m pip install --upgrade pip
```
9.12 Встановити потрібні бібліотеки:
```
pip install -r requirements.txt
```
9.13 Встановити модуль для відображеня візуалізацій:
```
sudo apt install -y python3-tk
```
9.14 Форматувати код згідно до стандартів PEP8:
```
black main.py
```
9.15 Для аналізу даних за весь період (01.2013 – 04.2017), введіть:
```
python main.py
```
9.16 Ознайомитися з додатковими параметрами запуску проєкту:
```
python main.py -h
```