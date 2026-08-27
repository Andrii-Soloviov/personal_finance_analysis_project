#!/usr/bin/env bash

echo
echo "**************"
echo "* ПІДГОТОВКА *"
echo "**************"
echo

echo "1. Встановлюю модуль ізольованих віртуальних оточень..."
if ! apt install python3.12-venv; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити необхідний модуль!"
    read -p "Натисніть Enter для виходу..."
    echo
    return
fi
echo
echo "Модуль віртуальних оточень встановлено успішно."
echo

echo "2. Створюю нове віртуальне оточення..."
if ! python3 -m venv .venv; then
    echo
    echo "[ПОМИЛКА] Не вдалося створити віртуальне середовище!"
    read -p "Натисніть Enter для виходу..."
    echo
    return
fi
echo
echo "Віртуальне оточення створено успішно."
echo

echo "3. Активую створене середовище..."
if ! source .venv/bin/activate; then
    echo
    echo "[ПОМИЛКА] Не вдалося активувати віртуальне середовище!"
    read -p "Натисніть Enter для виходу..."
    return
fi
echo
echo "Віртуальне оточення активовано."
echo

echo "4. Оновлюю менеджер пакетів pip до останньої версії..."
if ! python -m pip install --upgrade pip; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити останню версію менеджера пакетів!"
    read -p "Натисніть Enter для виходу..."
    return
fi
echo
echo "Менеджер пакетів оновлено до останньої версії."
echo

echo "5. Встановлюю необхідні бібліотеки..."
if ! pip install -r requirements.txt; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити pip-пакети!"
    read -p "Натисніть Enter для виходу..."
    return
fi
# друга частина
if ! sudo apt install -y python3-tk; then
    echo
    echo "[ПОМИЛКА] Не вдалося встановити системний пакет python3-tk!"
    read -p "Натисніть Enter для виходу..."
    return
fi
echo
echo "Всі потрібні бібліотеки було встановлено."
echo

echo "6. Форматую скрипт 'main.py' згідно до стандартів PEP8..."
if ! black main.py; then
    echo
    echo "[ПОМИЛКА] Не знайдено файл 'main.py' або не вдалося його форматувати!"
    read -p "Натисніть Enter для виходу..."
    return
fi
echo
echo "Скрипт 'main.py' було приведено до стандартів PEP8 успішно."
echo

echo "******************"
echo "* ЗАПУСК ПРОЕКТУ *"
echo "******************"
echo

echo "1. Для аналізу даних за весь період (01.2013 – 04.2017), введіть:"
echo "   python main.py"
echo

echo "2. Ознайомлення з додатковими параметрами запуску:"
echo "   python main.py -h"
echo
