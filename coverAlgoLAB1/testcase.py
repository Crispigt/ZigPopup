import random

def generate_test_case():
    test_cases = []
    for _ in range(30):  # Up to 30 test cases
        A = round(random.uniform(-1000, 1000), 6)
        B = round(random.uniform(A, A + random.uniform(0, 100)), 6)
        n = random.randint(1, 20000)
        intervals = []
        for _ in range(n):
            ai = round(random.uniform(A - 5, B + 5), 6)
            bi = round(random.uniform(ai, ai + random.uniform(0, 10)), 6)
            intervals.append((ai, bi))
        test_cases.append((A, B, intervals))
    return test_cases

def format_test_cases(test_cases):
    formatted_cases = []
    for A, B, intervals in test_cases:
        case_str = f"{A} {B}\n{len(intervals)}\n"
        for ai, bi in intervals:
            case_str += f"{ai} {bi}\n"
        formatted_cases.append(case_str.strip())
    return "\n".join(formatted_cases)

# Generate and save the test case to a file
test_cases = generate_test_case()
formatted_test_cases = format_test_cases(test_cases)

with open("big_test_case.txt", "w") as f:
    f.write(formatted_test_cases)

print("Test case file generated: big_test_case.txt")
