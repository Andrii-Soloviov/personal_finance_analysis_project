#!/bin/bash

echo
echo "**************"
echo "* ПІДГОТОВКА *"
echo "**************"
echo

echo "1. Створюю нове віртуальне оточення..."
if ! python3 -m venv .venv --without-scm-ignore-files; then
    echo
    echo "[ПОМИЛКА] Не вдалося створити віртуальне середовище!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
echo
echo "Віртуальне оточення створено успішно."
echo

echo "2. Активую створене середовище..."
if ! source .venv/bin/activate; then
    echo
    echo "[ПОМИЛКА] Не вдалося активувати віртуальне середовище!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
echo
echo "Віртуальне оточення активовано."
echo

echo "3. Оновлюю менеджер пакетів pip до останньої версії..."
if  ! python3 -m pip install --upgrade pip; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити останню версію менеджера пакетів!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
echo
echo "Менеджер пакетів оновлено до останньої версії."
echo

echo "4. Встановлюю туди необхідні бібліотеки..."
if ! pip install -r requirements.txt; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити необхідні пакети!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
# друга частина
if ! brew install python-tk; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити системний пакет python-tk!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
echo
echo "Всі потрібні модулі було встановлено."
echo

echo "5. Форматую скрипт 'main.py' згідно до стандартів PEP8..."
if ! black main.py; then
    echo
    echo "[ПОМИЛКА] Не знайдено файл 'main.py' або не вдалося його форматувати!"
    read -p "Натисніть Enter для виходу..."
    exit $?
fi
echo
echo "Скрипт 'main.py' було приведено до стандартів PEP8 успішно."
echo
echo

echo "******************"
echo "* ЗАПУСК ПРОЕКТУ *"
echo "******************"
echo
echo "1. Для аналізу даних за весь період (01.2013 – 04.2017), введіть:"
echo "   python3 main.py"
echo
echo "2. Ознайомлення з додатковими параметрами запуску:"
echo "   python3 main.py -h"
echo