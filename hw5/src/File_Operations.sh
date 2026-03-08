#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Використання: $0 <джерело> <призначення>"
    exit 1
fi

source_file="$1"
destination="$2"

if [ ! -f "$source_file" ]; then
    echo "Помилка: файл не існує"
    exit 1
fi

cp "$source_file" "$destination"
echo "Файл успішно скопійовано."