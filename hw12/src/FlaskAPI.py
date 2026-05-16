# Імпортуємо Flask та допоміжні функції
# Flask — основний клас застосунку
# request — дозволяє отримувати дані HTTP-запиту
# jsonify — перетворює Python-словники/списки у JSON-відповідь
from flask import Flask, request, jsonify

# csv — модуль для роботи з CSV-файлами
import csv

# os — потрібен для перевірки існування файлу
import os

# __name__ повідомляє Flask, де знаходиться поточний модуль
app = Flask(__name__)

# Назва CSV-файлу, у якому будуть зберігатися студенти
CSV_FILE = "students.csv"

# Список колонок CSV-файлу
FIELDS = ["id", "first_name", "last_name", "age"]

# =========================================================
# ФУНКЦІЯ СТВОРЕННЯ CSV-ФАЙЛУ
# =========================================================
def init_csv():

    # Якщо файл НЕ існує — створюємо його
    if not os.path.exists(CSV_FILE):

        # Відкриваємо файл у режимі запису
        # newline="" потрібен для коректної роботи CSV
        # encoding="utf-8" потрібен для українських символів
        with open(CSV_FILE, "w", newline="", encoding="utf-8") as file:

            # Створюємо CSV writer
            writer = csv.DictWriter(file, fieldnames=FIELDS)

            # Записуємо заголовки колонок
            writer.writeheader()

# =========================================================
# ФУНКЦІЯ ЧИТАННЯ ВСІХ СТУДЕНТІВ
# =========================================================
def read_students():

    # Переконуємося, що CSV-файл існує
    init_csv()

    # Відкриваємо файл у режимі читання
    with open(CSV_FILE, "r", newline="", encoding="utf-8") as file:

        # DictReader читає CSV як словники
        # Наприклад:
        # {
        #   "id": "1",
        #   "first_name": "Ivan",
        #   "last_name": "Petrenko",
        #   "age": "20"
        # }
        reader = csv.DictReader(file)

        # Перетворюємо reader у список
        return list(reader)

# =========================================================
# ФУНКЦІЯ ЗАПИСУ ВСІХ СТУДЕНТІВ У CSV
# =========================================================
def write_students(students):

    # Повністю перезаписуємо CSV-файл
    with open(CSV_FILE, "w", newline="", encoding="utf-8") as file:

        writer = csv.DictWriter(file, fieldnames=FIELDS)

        # Записуємо заголовки колонок
        writer.writeheader()

        # Записуємо всі записи студентів
        writer.writerows(students)

# =========================================================
# ГЕНЕРАЦІЯ НОВОГО ID
# =========================================================
def get_next_id(students):

    # Якщо студентів ще немає —
    # перший ID буде 1
    if not students:
        return "1"

    # Беремо максимальний ID
    # і додаємо +1
    return str(
        max(int(student["id"]) for student in students) + 1
    )

# =========================================================
# GET — ОТРИМАТИ ВСІХ СТУДЕНТІВ
# =========================================================
# URL:
# /students
#
# HTTP METHOD:
# GET
#
# Приклад:
# GET http://127.0.0.1:5000/students
# =========================================================
@app.route("/students", methods=["GET"])
def get_students():

    # Читаємо всіх студентів
    students = read_students()

    # Повертаємо JSON-відповідь
    return jsonify(students)

# =========================================================
# GET — ОТРИМАТИ СТУДЕНТА ПО ID
# =========================================================
# URL:
# /students/1
#
# <int:student_id>
# означає:
# Flask автоматично бере число з URL
# і передає його у student_id
# =========================================================
@app.route("/students/<int:student_id>", methods=["GET"])
def get_student(student_id):

    students = read_students()

    # Шукаємо студента по ID
    for student in students:

        # CSV зберігає значення як рядки,
        # тому перетворюємо ID у int
        if int(student["id"]) == student_id:

            # Якщо знайдено —
            # повертаємо студента
            return jsonify(student)

    # Якщо не знайдено —
    # повертаємо помилку 404
    return jsonify({
        "error": "Student not found"
    }), 404

# =========================================================
# GET — ПОШУК ПО ПРІЗВИЩУ
# =========================================================
# URL:
# /students/lastname/Petrenko
# =========================================================
@app.route("/students/lastname/<last_name>", methods=["GET"])
def get_students_by_last_name(last_name):

    students = read_students()

    # Створюємо список студентів,
    # у яких збігається прізвище
    result = [
        student for student in students
        if student["last_name"].lower() == last_name.lower()
    ]

    # Якщо нікого не знайдено
    if not result:
        return jsonify({
            "error": "Students with this last name not found"
        }), 404

    return jsonify(result)

# =========================================================
# POST — СТВОРЕННЯ НОВОГО СТУДЕНТА
# =========================================================
# URL:
# /students
#
# HTTP METHOD:
# POST
#
# JSON body:
# {
#   "first_name": "Ivan",
#   "last_name": "Petrenko",
#   "age": 20
# }
# =========================================================
@app.route("/students", methods=["POST"])
def add_student():

    # Отримуємо JSON із тіла запиту
    data = request.get_json()

    # Якщо тіло запиту порожнє
    if not data:
        return jsonify({
            "error": "Request body is empty"
        }), 400

    # Дозволені поля
    allowed_fields = {
        "first_name",
        "last_name",
        "age"
    }

    # Перевірка:
    # чи немає зайвих полів
    #
    # Наприклад:
    # "salary"
    # "city"
    # тощо
    if set(data.keys()) - allowed_fields:

        return jsonify({
            "error": "Unknown field in request body"
        }), 400

    # Перевірка:
    # чи всі обов’язкові поля передані
    if not allowed_fields.issubset(data.keys()):

        return jsonify({
            "error": "Required fields: first_name, last_name, age"
        }), 400

    students = read_students()

    # Створюємо нового студента
    student = {
        "id": get_next_id(students),
        "first_name": data["first_name"],
        "last_name": data["last_name"],
        "age": str(data["age"])
    }

    # Додаємо у список
    students.append(student)

    # Записуємо у CSV
    write_students(students)

    # 201 = Created
    return jsonify(student), 201

# =========================================================
# PUT — ПОВНЕ ОНОВЛЕННЯ СТУДЕНТА
# =========================================================
# PUT зазвичай означає:
# повністю замінити ресурс
#
# Треба передати ВСІ поля
# =========================================================
@app.route("/students/<int:student_id>", methods=["PUT"])
def update_student(student_id):

    data = request.get_json()

    if not data:
        return jsonify({
            "error": "Request body is empty"
        }), 400

    allowed_fields = {
        "first_name",
        "last_name",
        "age"
    }

    if set(data.keys()) - allowed_fields:

        return jsonify({
            "error": "Unknown field in request body"
        }), 400

    if not allowed_fields.issubset(data.keys()):

        return jsonify({
            "error": "Required fields: first_name, last_name, age"
        }), 400

    students = read_students()

    # Шукаємо студента
    for student in students:

        if int(student["id"]) == student_id:

            # Оновлюємо всі поля
            student["first_name"] = data["first_name"]
            student["last_name"] = data["last_name"]
            student["age"] = str(data["age"])

            # Зберігаємо зміни
            write_students(students)

            return jsonify(student)

    return jsonify({
        "error": "Student not found"
    }), 404

# =========================================================
# PATCH — ЧАСТКОВЕ ОНОВЛЕННЯ
# =========================================================
# PATCH тут змінює лише age
# =========================================================
@app.route("/students/<int:student_id>", methods=["PATCH"])
def patch_student(student_id):

    data = request.get_json()

    if not data:
        return jsonify({
            "error": "Request body is empty"
        }), 400

    # PATCH дозволяє ТІЛЬКИ поле age
    if set(data.keys()) != {"age"}:

        return jsonify({
            "error": "PATCH supports only field: age"
        }), 400

    students = read_students()

    for student in students:

        if int(student["id"]) == student_id:

            # Оновлюємо лише age
            student["age"] = str(data["age"])

            write_students(students)

            return jsonify(student)

    return jsonify({
        "error": "Student not found"
    }), 404

# =========================================================
# DELETE — ВИДАЛЕННЯ СТУДЕНТА
# =========================================================
@app.route("/students/<int:student_id>", methods=["DELETE"])
def delete_student(student_id):

    students = read_students()

    for student in students:

        if int(student["id"]) == student_id:

            # Видаляємо студента зі списку
            students.remove(student)

            # Перезаписуємо CSV
            write_students(students)

            return jsonify({
                "message": f"Student with id {student_id} deleted successfully"
            })

    return jsonify({
        "error": "Student not found"
    }), 404

# =========================================================
# ТОЧКА ЗАПУСКУ ПРОГРАМИ
# =========================================================
if __name__ == "__main__":

    # Створюємо CSV-файл при старті
    init_csv()

    # Запуск Flask-сервера
    #
    # debug=True:
    # - автоматичне перезавантаження
    # - показ помилок у браузері
    app.run(debug=True)