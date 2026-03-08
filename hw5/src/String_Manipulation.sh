#!/bin/bash
#питаєм\читаєм ввід
read -p "Введіть речення: " sentence
#перевертаєм
echo "$sentence" | tr ' ' '\n' | tac | tr '\n' ' '
echo