import pandas as pd  #  робота з табличними даними
import numpy as np  #  робота з великими масивами даних
import openpyxl as xl  #  робота з данми у форматі '.xlsx'
import argparse  #  парсинг аргументів командного рядка
import calendar  #  підрахунок кількості днів у місяці
import os  #  робота з файловою системою
import glob  #  отримати список файлів у директорії з робочими книгами
import subprocess  #  запуск скрипта у окремому процесі
import webbrowser  #  перехід по посиланню за допомогою браузера
from natsort import natsorted  #  сортування списків у природному порядку
from dotenv import load_dotenv  #  робота з env змінними

#  робота з реляційною базою даних PostgreSQL
from tabulate import tabulate  #  вирівнювання друкованих даних
from sqlalchemy import create_engine, text, Table, Column, Integer, String, MetaData
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase

# Визначимо додтакові змінні
WORKBOOKS_DEFAULT_DIR = "./data/workbooks"
CSV_MONTHLY_DIR = "./data/csv/monthly"
CSV_YEARLY_DIR = "./data/csv/yearly"
CSV_PERIOD_DIR = "./data/csv/period"
SQL_FILE_DIR = "./data/sql"
JUPYTER_FILE_DIR = "./data/jupyter"
PYTHON_FILE_DIR = "./data/python"
MANDATORY_ENV_VARS = [
    "POSTGRES_HOST",
    "POSTGRES_DB",
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
]
CATEGORIES = [
    "weekday",
    "record_date",
    "salary",
    "other_income",
    "food",
    "travel",
    "health",
    "household_goods",
    "apartment",
    "debts",
    "clothes_shoes",
    "other_expenses",
    "alcohol",
    "tasties",
    "events",
    "entertainment",
]


# ф-ція з'єднання з базою PostgreSQL
def get_db_connection(
    db_host: str,
    db_name: str,
    db_user: str,
    db_password: str,
    db_port: int,
):
    url = URL.create(
        drivername="postgresql+psycopg",
        username=db_user,
        password=db_password,
        host=db_host,
        port=db_port,
        database=db_name,
    )
    engine = create_engine(url, pool_pre_ping=True, pool_recycle=3600, echo=False)
    return engine


# функція видалення csv-файлів, що залишился з попереднього запуску програми
def remove_old_csv(path_old_files: str, period: str):
    # перевіряємо наявність csv-файлів у відповідній дерикторії
    csv_files = glob.glob(os.path.join(path_old_files, "*.csv"))
    # умови обробки csv-файлів
    if csv_files:
        print(
            f"\nЗнайдено попередніх CSV-файлів за {period}: {len(csv_files)}. Видаляю...\n"
        )
        for old_files in natsorted(csv_files):
            try:
                os.remove(old_files)
                print(f"Видалено файл: {os.path.basename(old_files)}")
            except Exception as e:
                print(f"Не вдалося видалити {os.path.basename(old_files)}: {e}")
    else:
        print("Попередніх CSV-файлів не знайдено.\n")


# ф-ція обробки місячних даних
def monthly_csv(workbook: str):
    # завантажуємо робочу книгу Excel з даними за рік
    xls_content = xl.load_workbook(workbook)
    sheets = xls_content.sheetnames

    for month, sheet_name in enumerate(sheets, start=1):
        # звітний рік
        year = int(os.path.basename(workbook)[:4])
        # кількість днів у місяці
        days = calendar.monthrange(year, month)[1]
        # зчитуємо вхідні місячні дані формату excel
        monthly = pd.read_excel(workbook, sheet_name=sheet_name)
        # налаштовуємо відображення таблиць без переносу даних
        pd.set_option("display.max_colwidth", None)
        pd.set_option("display.width", 1000)
        if month % 3 == 0:
            print(f"Вхідні дані за {sheet_name} мають вигляд:\n{monthly.head()}\n")

        # за наявності, замінюємо пробіли на порожні значення (NaN)
        monthly = monthly.replace(r"^\s*$", pd.NA, regex=True)
        # видаляємо рядки/стовбці, що не містять даних:
        monthly = monthly.dropna(how="all")
        monthly = monthly.dropna(how="all", axis=1)
        # видаляємо зайві стовбці та змінюємо назви існуючих
        monthly = monthly.iloc[
            :, 2:-3
        ]  # -перші 2 та останні 3 стовбця завжди можна видаляти
        monthly.columns = range(len(monthly.columns))

        # Для подальшого аналізу залишимо лише дані за кожен день
        # перетворюємо таблицю у зручний формат
        monthly = monthly.transpose()
        # привласнюємо перший рядок (індекс 0) назвам стовпців
        monthly.columns = monthly.iloc[0]
        # видаляємо "нульове" ім'я стовбців
        monthly.columns.name = None
        # видаляємо перший рядок таблиці та скидаємо нумерацію індексів
        monthly = monthly.iloc[1:]
        monthly.reset_index(inplace=True)
        # залишаємо тільки НЕ агреговані дані за кожен день
        monthly = monthly.loc[: (days - 1), :"Розваги"]
        # ПОЯСНЕННЯ: нижня межа табличних даних завжди буде визначатися як: кількість днів у поточному місяці мінус 1,
        # тому що мітки рядків починаються з "0". Ліва межа табличних даних завжди буде обмежуватися стовбчиком: "Розваги".

        # створюємо словник для перейменування відповідних назв категорій
        names_mapping = {
            "index": "weekday",
            np.nan: "record_date",  # "np.nan" - коректне позначення пустої комірки для присвоєння назви стовбчика з датою
            "Зарплата": "salary",
            "Інші доходи": "other_income",
            "Харчування": "food",
            "Проїзд": "travel",
            "Здоров'я": "health",
            "Госп.Товари": "household_goods",
            "Квартира": "apartment",
            "Борги": "debts",
            "Речі та взуття": "clothes_shoes",
            "Інші витрати": "other_expenses",
            "Алкоголь": "alcohol",
            "Смаколики": "tasties",
            "Заходи": "events",
            "Розваги": "entertainment",
        }
        # оновлюємо назви категорій доходів та витрат
        monthly = monthly.rename(columns=names_mapping)

        # Приведемо часові дані до більш наглядного та зручного формату
        # визначаємо діапазон дат для поточного місяця
        start_date = "{}-{}-01".format(year, month)
        end_date = "{}-{}-{}".format(year, month, days)
        # створюємо список діпазону дат за місяць
        date_list = pd.date_range(start=start_date, end=end_date, freq="D")
        # явно вказуємо формат для отриманих дат
        date = date_list.strftime("%Y-%m-%d")
        # оновлюємо стовбчик з переліком дат
        monthly["record_date"] = date
        # створюємо список днів тижня відповідно отриманим датам
        weekday = date_list.strftime("%a")
        # оновлюємо стовбчик з днями тижня
        monthly["weekday"] = weekday
        if month % 3 == 0:
            print(
                f"Після усіх етапів обробки дані за {sheet_name} мають вигляд:\n{monthly.head()}\n"
            )

        # Зберігаємо оброблені дані за кожен місяць у форматі '.csv'
        monthly.to_csv(
            "{}/{}_{}.csv".format(CSV_MONTHLY_DIR, year, month), sep=",", index=False
        )


def data_processing_logic(args):
    # обробка міс. даних у разі використання річного фільтру "-y"
    filter_by_years = list()
    if args.year:
        for list_years in args.year:
            filter_by_years.append(list_years)
    # обробка міс. даних у разі відсутності аргумента "-y"
    else:
        all_years = ""
        for workbook in glob.glob(f"{args.workbookdir}/{all_years}*"):
            year = int(os.path.basename(workbook)[:4])
            filter_by_years.append(year)

    # обробка міс. даних у разі відсутності аргумента "-s".
    if not args.skip_monthly_generation:
        # видалення csv-файлів за кожен Місяць, що залишилися з попереднього запуску
        remove_old_csv(path_old_files=CSV_MONTHLY_DIR, period="місяць")
        # обробка міс. даних
        for year in filter_by_years:
            for workbook in glob.glob(f"{args.workbookdir}/{year}*"):
                print("\nОбробляю робочу книгу:", workbook, "\n")
                monthly_csv(workbook=workbook)
    # обробка міс. даних у разі використання аргумента "-s".
    else:
        # Отримуємо список унікальних років для csv-файлів, що було сгенеровано при попередньому запуску коду
        last_list = sorted(
            {
                int(os.path.basename(file).split("_")[0])
                for file in glob.glob(f"{CSV_MONTHLY_DIR}/*.csv")
            }
        )
        # перевірка чи отриманий список НЕ пустий та містить роки, що було введено у запиті
        if last_list:
            # перевірка чи містить отриманий список роки, що було введено у запиті
            if set(filter_by_years).issubset(set(last_list)):
                print(f"\nМісячні дані за цей період було згенеровано раніше")
            else:
                raise ValueError(
                    "Нажаль, Ви ще не можете використовувати аргумент '-s' для обраного періоду\n"
                )
        else:
            raise ValueError(
                "Нажаль, Ви ще не можете використовувати аргумент '-s' для обраного періоду\n"
            )
    return filter_by_years


# ф-ція обробки річних даних
def yearly_csv(files: list, year: int):
    # об'єднуємо усі дані за поточний рік у спільну таблицю
    yearly = pd.concat(
        # вираз-генератор
        [pd.read_csv(f, sep=",") for f in natsorted(files)],
        axis=0,
        ignore_index=True,
    )
    # зазначимо певну послідовність категорій
    yearly = yearly.reindex(columns=CATEGORIES)
    print(f"\nОтримуємо зведену таблицю за {year} рік:\n{yearly}")
    # зберігаємо об'єднані дані за рік у форматі '.csv'
    yearly.to_csv(f"{CSV_YEARLY_DIR}/{year}.csv", sep=",", index=False)


# ф-ція обробки даних за весь період
def period_csv():
    csvs = glob.glob(f"{CSV_YEARLY_DIR}/*.csv")
    # об'єднуємо усі дані за досліджувальний період у спільну таблицю
    period = pd.concat(
        [pd.read_csv(c, sep=",") for c in natsorted(csvs)], axis=0, ignore_index=True
    )
    # зазначимо певну послідовність категорій
    period = period.reindex(columns=CATEGORIES)
    print(
        f"\nРезультуюча таблиця щоденних тразакцій за досліджувальний Період:\n{period}\n\n"
    )
    # зберігаємо об'єднані дані за досліджувальний період у форматі '.csv'
    period_file_path = f"{CSV_PERIOD_DIR}/data_period.csv"
    period.to_csv(period_file_path, sep=",", index=False)

    return period_file_path


# ф-ція очищення статрих та створення нових таблиць у базі PostgreSQL
def create_db_tables(engine):
    commands = (
        # попереднє видалення таблиць, що існували раніше
        "DROP TABLE IF EXISTS data_period CASCADE",
        "DROP TABLE IF EXISTS day_stat",
        "DROP TABLE IF EXISTS concl_day_stat",
        "DROP TABLE IF EXISTS trans_stat ",
        "DROP TABLE IF EXISTS concl_trans_stat ",
        "DROP TABLE IF EXISTS year_stat",
        "DROP TABLE IF EXISTS schema_year_stat",
        "DROP TABLE IF EXISTS concl_year_stat",
        # створення схеми для вхідних табл. даних за досліждувальний період
        """
            CREATE TABLE IF NOT EXISTS data_period (
                weekday varchar(50) NULL,
                record_date DATE NULL,
                salary float4 NULL,
                "other_income" float4 NULL,
                food float4 NULL,
                travel float4 NULL,
                health float4 NULL,
                household_goods float4 NULL,
                apartment float4 NULL,
                debts float4 NULL,
                clothes_shoes float4 NULL,
                other_expenses float4 NULL,
                alcohol float4 NULL,
                tasties float4 NULL,
                events float4 NULL,
                entertainment float4 NULL
            )
        """,
    )
    with engine.connect() as connection:
        for c in commands:
            connection.execute(text(c))
            connection.commit()


# ф-ція завантаження даних за весь період у базу PostgreSQL
def csv_to_db(db_connection, file_path, table):
    df = pd.read_csv(file_path)
    # приведення колонки до типу date
    df["record_date"] = pd.to_datetime(df["record_date"]).dt.date
    # завантаження даних у створену таблицю
    df.to_sql(table, con=db_connection, if_exists="append", index=False)


# ф-ція виконання початкових аналітичних розрахунків
def prepare_sql_tables(engine):
    print("\nЗапускаю SQL-скрипт з початковими аналітичними розрахунками...")
    # зчитування підготовленого sql-скрипта
    sql_file_path = f"{SQL_FILE_DIR}/create_tables.sql"
    with open(sql_file_path, "r", encoding="utf-8") as f:
        sql_schema = f.read()

    conn = engine.raw_connection()

    # виконання зчитанного sql-скрипта построково
    try:
        with conn.cursor() as cur:
            cur.execute(sql_schema)

        conn.commit()
        print("SQL-скрипт успішно виконано. Роздрук результатів:\n")

    except Exception as e:
        conn.rollback()
        print(f"Помилка: {e}")
        raise

    finally:
        conn.close()


# ф-ція зчитування результатів sql-скрипта та їх роздрук
def execute_sql_query(engine):
    # отримання табличних даних, що були згенеровані за доп. sql-скрипта
    df_day = pd.read_sql("SELECT * FROM day_stat", engine)
    df_concl_day = pd.read_sql("SELECT * FROM concl_day_stat", engine)
    df_trans = pd.read_sql("SELECT * FROM trans_stat", engine)
    df_concl_trans = pd.read_sql("SELECT * FROM concl_trans_stat", engine)
    df_year = pd.read_sql("SELECT * FROM year_stat", engine)
    df_concl_year = pd.read_sql("SELECT conclusions FROM concl_year_stat", engine)

    # налаштування зовн. вигляду отриманих табличних даних
    df_day = df_day.to_markdown(index=False)
    df_concl_day = df_concl_day.to_markdown(index=False)
    df_trans = df_trans.to_markdown(index=False)
    df_concl_trans = df_concl_trans.to_markdown(index=False)
    df_year = df_year.to_markdown(index=False)
    df_concl_year = df_concl_year.to_markdown(index=False)

    # роздрук табличних результатів та висновків
    print(f"\n1.1 ЧАСОВА АНАЛІТИКА НА РІВНІ - 'ДЕНЬ':\n\n{df_day}")
    print(f"\n1.2 ВИСНОВКИ:\n\n{df_concl_day}\n")
    print(f"\n2.1 АНАЛІТИКА ДАНИХ НА РІВНІ - 'ТРАНЗАКЦІЯ':\n\n{df_trans}")
    print(f"\n2.2 ВИСНОВКИ:\n\n{df_concl_trans}\n")
    print(f"\n3.1 АНАЛІТИКА НАДХОДЖЕНЬ/ВИТРАТ НА РІВНІ - 'РІК':\n\n{df_year}\n")
    print("3.2 ВІЗУАЛІЗАЦІЇ:\n")
    print("-3.2.1 'Доходи'")
    print("-3.2.2 'Витрати'")
    print("-3.2.3 'Середнє для річних показників Бюджету'")
    print(f"\n3.3 ВИСНОВКИ:\n\n{df_concl_year}\n")


# ф-ція конвертування jupyter-скрипта, виконання перетвореного файлу та роздрук результатів
def execute_jupyter_script():
    # шляхи до вхідного та конвертованого файлів
    jupyter_file_path = f"{JUPYTER_FILE_DIR}/part_in_jupyter.ipynb"
    python_folder_path = f"{PYTHON_FILE_DIR}"
    # ім'я конвертованого файла
    new_name = "converted_jupyter_part"
    print(
        "\nКонвертую jupyter-скрипт та зберігаю реузльтат у директорію './data/python':"
    )
    # функція ковертації jupyter-скрипта у python-скрипт
    os.system(
        f'jupyter nbconvert --to python "{jupyter_file_path}" --output-dir="{python_folder_path}" --output "{new_name}"'
    )
    # знаходимо папку, де лежить запущений скрипт 'main.py'
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # збираємо шлях до файлу, що є частиною проєкту, яку потрібно запустити
    script_path = os.path.join(
        current_dir, "data", "python", "converted_jupyter_part.py"
    )
    # запуск файлу, що є частиною проєкту
    result = subprocess.run(
        ["python", "-u", script_path], capture_output=True, text=True
    )
    print("\nЗапускаю python-скрипт з основними аналітичними розрахунками...")
    if result.stderr:
        print("ПОМИЛКИ ПІД ЧАС ВИКОНАННЯ:\n\n", result.stderr)
    else:
        print("python-скрипт успішно виконано. Роздрук результатів:")
        print(result.stdout)


# ф-ція переходу за посиланням для відображення частини проєкту, що створена у Power BI
def load_link():
    # посилання на web-версію Power BI
    link = "https://app.powerbi.com/view?r=eyJrIjoiOTJjOGI4YzMtMTM4NS00MzI5LThkODUtYzM2ZWJiYjBiZjM3IiwidCI6ImU0YjU0MWFlLTA0ZTktNGZiZS1iZjkyLTU0ODQ4NTNkZDEwMyJ9"
    # перехід за посиланням у браузері
    print("\nПереходжу за посиланням для виконання деяких кроків EDA...\n")
    print(
        "УВАГА: на 'Титульному листі' за допомогою випадаючого списку оберіть роки, які потрібно обробити!\n"
    )
    webbrowser.open(link)
    # супровідний текст
    print("ВІЗУАЛІЗАЦІЇ:\n")
    print("1. 'Титульний лист'")
    print("2. 'Дослідження Пропусків у даних'")
    print("3. 'Описова аналітика на рівні Дня'")
    print("4. 'Гістограми розподілу Доходів/Витрат'")
    print("5. 'Дослідження значущих категорій'")
    print("6. 'Box-plot аналіз деяких категорій'")
    print("7. 'Кореляційний аналіз активності категорій'\n")

    print(
        "-  Якщо перехід на web-сторінку для виконання EDA не здійснився, скористайтеся посиланням нижче:"
    )
    print("  ", link, "\n\n")


# основна функція
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-d",
        "--workbookdir",
        default=WORKBOOKS_DEFAULT_DIR,
        help="Шлях до директорії з робочими книгами Excel у разі зміни їх розташування",
    )
    parser.add_argument(
        "-y",
        "--year",
        nargs="*",
        type=int,
        help="""Обробити дані за певний рік або декілька років, що йдуть один за одним. 
                Кома НЕ потрібна!""",
    )
    parser.add_argument(
        "-s",
        "--skip_monthly_generation",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="""НЕ генерувати csv файли зі статистикою за кожен місяць.
                Корисно при повторному запуску скрипта за той самий період""",
    )
    args = parser.parse_args()

    # завантажуємо змінні з файлу .env:
    load_dotenv()
    # перевірка наявності всіх необхідних змінних
    for var in MANDATORY_ENV_VARS:
        if var not in os.environ:
            raise EnvironmentError("Failed because {} is not set.".format(var))

    # привласнюємо відповідні значення:
    db_host = os.getenv("POSTGRES_HOST")
    db_name = os.getenv("POSTGRES_DB")
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")
    db_port = os.getenv("POSTGRES_PORT")

    # спроба з'єднання з базою PostgreSQL
    try:
        engine = get_db_connection(
            db_host=db_host,
            db_name=db_name,
            db_user=db_user,
            db_password=db_password,
            db_port=db_port,
        )
        print("\nПробую з'єднатися з базою PostgreSQL...")
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            print(
                f"Connection to the '{db_host}' for user '{db_user}' created successfully.\n\n"
            )  # -повідомлення у разі вдалого з'єднання
    except Exception as ex:
        print(
            "Connection could not be made due to the following error:\n", ex
        )  # -повідомлення у разі невдалого з'єднання
        # аварійно завершуємо програму
        exit(1)

    print("****************************")
    print("* I. ОБРОБКА ВХІДНИХ ДАНИХ *")
    print("****************************")

    # Створення логіки обробки введених даних
    filter_by_years = data_processing_logic(args=args)

    # Видалення csv-файлів за кожен Рік, що залишилися з попереднього запуску
    remove_old_csv(path_old_files=CSV_YEARLY_DIR, period="рік")

    # Обробляємо список csv-файлів за кожен рік
    for year in filter_by_years:
        csvs = glob.glob(f"{CSV_MONTHLY_DIR}/{year}*.csv")
        yearly_csv(files=csvs, year=year)

    # Видалення csv-файлів за весь Період, що залишилися з попереднього запуску
    remove_old_csv(path_old_files=CSV_PERIOD_DIR, period="досліджувальний період")

    # Генерація CSV за досліджувальний період
    period_file_path = period_csv()

    # Створення схеми для вхідних даних у базі PostgreSQL
    create_db_tables(engine=engine)

    # Завантаження data_period.csv у базу PostgreSQL
    csv_to_db(db_connection=engine, file_path=period_file_path, table="data_period")

    print("***********************************************")
    print("* II. ОПИСОВА СТАТИСТИКА ТА ВІЗУАЛЬНИЙ АНАЛІЗ *")
    print("***********************************************")

    # Виконання основних аналітичних розрахунків у базі PostgreSQL
    prepare_sql_tables(engine=engine)

    # Зчитування результатів sql-скрипта та їх роздрук
    execute_sql_query(engine=engine)

    # конвертування jupyter-скрипта, його виконання та роздрук результатів
    execute_jupyter_script()

    print("**********************************************")
    print("* III. ДОСЛІДНИЦЬКИЙ АНАЛІЗ ДАНИХ У POWER BI *")
    print("**********************************************")

    # перехід за посиланням для відображення частини проєкту, що створена у Power BI
    load_link()

    print("********************************************************")
    print("* АНАЛІЗ ОСОБИСТИХ ФІНАНСІВ ЗАВЕРШЕНО, ДЯКУЮ ЗА УВАГУ! *")
    print("********************************************************\n")


if __name__ == "__main__":
    main()
