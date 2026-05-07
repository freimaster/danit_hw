class Alphabet:
    def __init__(self, lang, letters):
        self.lang = lang
        self.letters = letters

    def print(self):
        print(" ".join(self.letters))

    def letters_num(self):
        return len(self.letters)


class EngAlphabet(Alphabet):
    _letters = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    _letters_num = len(_letters)

    def __init__(self):
        super().__init__("En", EngAlphabet._letters)

    def is_letter(self, letter):
        return letter.upper() in self.letters

    def letters_num(self):
        return EngAlphabet._letters_num

    @staticmethod
    def example():
        return "example of text in English language."


class UaAlphabet(Alphabet):
    _letters = list("АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯ")
    _letters_num = len(_letters)

    def __init__(self):
        super().__init__("UA", UaAlphabet._letters)

    def is_letter(self, letter):
        return letter.upper() in self.letters

    def letters_num(self):
        return UaAlphabet._letters_num

    @staticmethod
    def example():
        return "приклад тексту українською мовою"


def show_class_info(obj, parent_class):
    print("\n=== ІНФОРМАЦІЯ ПРО ОБ'ЄКТ ===")
    print("Тип об'єкта:", type(obj))
    print("Назва класу:", obj.__class__.__name__)
    print("Батьківський клас:", parent_class.__name__)
    print("Мова:", obj.lang)
    print("Кількість літер:", obj.letters_num())
    print("Перші 5 літер:", obj.letters[:5])


def choose_language():
    while True:
        print("\n=== ВИБІР МОВИ ===")
        print("1 - Англійський алфавіт")
        print("2 - Український алфавіт")
        print("0 - Назад")

        lang_choice = input("Оберіть мову: ")

        if lang_choice == "1":
            return eng

        elif lang_choice == "2":
            return ua

        elif lang_choice == "0":
            return None

        else:
            print("Невірний вибір.")


def main():
    global eng, ua

    eng = EngAlphabet()
    ua = UaAlphabet()

    while True:
        print("\n========== MENU ==========")
        print("1 - Показати алфавіт")
        print("2 - Кількість літер")
        print("3 - Перевірити літеру")
        print("4 - Приклад тексту")
        print("5 - Інформація про об'єкт")
        print("0 - Вихід")

        choice = input("Оберіть пункт меню: ")

        if choice == "1":
            alphabet = choose_language()

            if alphabet:
                print("\nАлфавіт:")
                alphabet.print()

        elif choice == "2":
            alphabet = choose_language()

            if alphabet:
                print("\nКількість літер:")
                print(alphabet.letters_num())

        elif choice == "3":
            alphabet = choose_language()

            if alphabet:
                letter = input("Введіть літеру: ")

                print("\nРезультат перевірки:")
                print(alphabet.is_letter(letter))

        elif choice == "4":
            alphabet = choose_language()

            if alphabet:
                print("\nПриклад тексту:")
                print(alphabet.example())

        elif choice == "5":
            alphabet = choose_language()

            if alphabet:
                show_class_info(alphabet, Alphabet)

        elif choice == "0":
            print("Вихід з програми.")
            break

        else:
            print("Невідома команда.")


if __name__ == "__main__":
    main()