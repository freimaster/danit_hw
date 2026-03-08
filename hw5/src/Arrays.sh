#!/bin/bash
#оголошуєм масив
fruits=("Apple" "Banana" "Orange" "Mango" "Pear")

#проходимо по елементах масиву
for fruit in "${fruits[@]}"
do
    # Виводимо елемент
    echo "$fruit"
done