import sys
import random

def main():
    N = 1000000
    Q = 1000000
    
    print(N, Q)
    
    for _ in range(Q):
        op = random.choices(["=", "?"], weights=[0.5, 0.5], k=1)[0]
        
        a = random.randint(0, N-1)
        b = random.randint(0, N-1)
        while b == a:
            b = random.randint(0, N-1)
        
        print(op, a, b)

if __name__ == "__main__":
    main()
