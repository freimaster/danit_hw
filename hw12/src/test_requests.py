import requests
import time
import json

BASE_URL = "http://127.0.0.1:5000"
RESULTS_FILE = "results.txt"
WAIT_SECONDS = 15


def write_result(text):
    print(text)
    with open(RESULTS_FILE, "a", encoding="utf-8") as file:
        file.write(text + "\n")


def print_response(response):
    write_result(f"Status code: {response.status_code}")

    try:
        data = response.json()
        formatted = json.dumps(data, ensure_ascii=False, indent=4)
        write_result("Response JSON:")
        write_result(formatted)
    except ValueError:
        write_result("Response text:")
        write_result(response.text)

    write_result("-" * 70)


def run_step(title, method, url, json_data=None):
    write_result("\n" + "=" * 70)
    write_result(title)
    write_result(f"Method: {method}")
    write_result(f"URL: {url}")

    if json_data is not None:
        write_result("Request body:")
        write_result(json.dumps(json_data, ensure_ascii=False, indent=4))

    try:
        response = requests.request(method, url, json=json_data)
        print_response(response)
        return response

    except requests.exceptions.RequestException as error:
        write_result(f"Request error: {error}")
        write_result("-" * 70)
        return None

    finally:
        time.sleep(WAIT_SECONDS)


def main():
    # Очищаємо results.txt перед новим запуском
    with open(RESULTS_FILE, "w", encoding="utf-8") as file:
        file.write("REST API test results\n")
        file.write("=" * 70 + "\n")

    # 1. Отримати всіх наявних студентів
    run_step(
        "TEST 1: Отримати всіх наявних студентів (GET)",
        "GET",
        f"{BASE_URL}/students"
    )

    # 2. Створити трьох студентів
    student_1 = {
        "first_name": "Ivan",
        "last_name": "Petrenko",
        "age": 20
    }

    student_2 = {
        "first_name": "Olena",
        "last_name": "Shevchenko",
        "age": 21
    }

    student_3 = {
        "first_name": "Andrii",
        "last_name": "Kovalenko",
        "age": 22
    }

    response_1 = run_step(
        "TEST 2.1: Створити першого студента (POST)",
        "POST",
        f"{BASE_URL}/students",
        student_1
    )

    response_2 = run_step(
        "TEST 2.2: Створити другого студента (POST)",
        "POST",
        f"{BASE_URL}/students",
        student_2
    )

    response_3 = run_step(
        "TEST 2.3: Створити третього студента (POST)",
        "POST",
        f"{BASE_URL}/students",
        student_3
    )

    first_student_id = response_1.json()["id"]
    second_student_id = response_2.json()["id"]
    third_student_id = response_3.json()["id"]

    # 3. Отримати всіх студентів
    run_step(
        "TEST 3: Отримати інформацію про всіх наявних студентів (GET)",
        "GET",
        f"{BASE_URL}/students"
    )

    # 4. Оновити вік другого студента
    run_step(
        "TEST 4: Оновити вік другого студента (PATCH)",
        "PATCH",
        f"{BASE_URL}/students/{second_student_id}",
        {
            "age": 25
        }
    )

    # 5. Отримати інформацію про другого студента
    run_step(
        "TEST 5: Отримати інформацію про другого студента (GET)",
        "GET",
        f"{BASE_URL}/students/{second_student_id}"
    )

    # 6. Оновити імʼя, прізвище та вік третього студента
    run_step(
        "TEST 6: Оновити імʼя, прізвище та вік третього студента (PUT)",
        "PUT",
        f"{BASE_URL}/students/{third_student_id}",
        {
            "first_name": "Maksym",
            "last_name": "Bondarenko",
            "age": 23
        }
    )

    # 7. Отримати інформацію про третього студента
    run_step(
        "TEST 7: Отримати інформацію про третього студента (GET)",
        "GET",
        f"{BASE_URL}/students/{third_student_id}"
    )

    # 8. Отримати всіх студентів
    run_step(
        "TEST 8: Отримати всіх наявних студентів (GET)",
        "GET",
        f"{BASE_URL}/students"
    )

    # 9. Видалити першого користувача
    run_step(
        "TEST 9: Видалити першого студента (DELETE)",
        "DELETE",
        f"{BASE_URL}/students/{first_student_id}"
    )

    # 10. Отримати всіх студентів
    run_step(
        "TEST 10: Отримати всіх наявних студентів після видалення (GET)",
        "GET",
        f"{BASE_URL}/students"
    )

    write_result("\nTesting finished. Results saved to results.txt")


if __name__ == "__main__":
    main()