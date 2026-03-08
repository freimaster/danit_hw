#!/bin/bash
WATCH_DIR="$HOME/watch"
mkdir -p "$WATCH_DIR"
while true
do
    for file in "$WATCH_DIR"/*; do
        #якщо файлів немає пропуск
        [ -e "$file" ] || continue
        #пропускаємо оброблені
        [[ "$file" == *.back ]] && continue
        #виводимо вміст
        cat "$file"
        #перейменовуємо
        mv "$file" "$file.back"
    done
    #чекаємо інтервал часу
    sleep 5
done