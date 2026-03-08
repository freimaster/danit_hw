#!/bin/bash
#randomgen 1 - 100
number=$((RANDOM % 100 + 1))
attempts=5 #к-ть спроб

for ((i=1; i<=attempts; i++))
do
    #ask num
    read -p "Спроба $i/5. Вгадайте число (1-100): " guess
    #check num
    if [ "$guess" -eq "$number" ]; then
        echo "Congratulations! You guessed the right number."
        exit 0
    fi
    #low\hi message
    if [ "$guess" -gt "$number" ]; then
        echo "Too high"
    else
        echo "Too low"
    fi
done
#out of attempts
echo "Sorry, you've run out of attempts. The correct number was $number"