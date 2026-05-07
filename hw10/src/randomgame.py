import random

def main():
    # Генерeруєм число
    secret_n = random.randint(1, 100)
    
    max_att = 5
    att = 0
#    print(f"{secret_n}")
    print("Вгадайте число від 1 до 100.")
    print(f"У вас є {max_att} спроб.")

    while att < max_att:
        try:
            #очікєм ввід. менше 1 і більше 100 - помилка
            uinput = int(input("Введіть ваше число: "))
            if uinput < 1 or uinput > 100:
                raise ValueError

            att += 1

            # Перевірка числа
            if uinput == secret_n:
                print("Вітаємо! Ви вгадали правильне число.")
                return
            elif uinput > secret_n:
                print("Занадто високо.")
            elif uinput < secret_n:
                print("Занадто низько.")

            # Виводим "Залишилось спроб"
            print(f"Залишилось спроб: {max_att - att}")

        except ValueError:
            print("Будь ласка, введіть коректне ціле число.")

    # Спроби використані
    print(f"У вас закінчилися спроби. Правильне число: {secret_n}")

# Виклик функції
if __name__ == "__main__":
    main()