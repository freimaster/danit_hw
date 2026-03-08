#!/bin/bash
read -p "Введіть назву файлу: " filename
if [ -f "$filename" ]; then
    echo "Файл існує."
else
    echo "Файл не існує."
fi