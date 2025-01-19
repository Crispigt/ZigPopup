import random
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate subset sum instances.")
    parser.add_argument('n', type=int,
                        help='how many numbers in the instance')
    parser.add_argument('-size', type=int, default=2**25,
                        help='max size of the numbers')
    parser.add_argument('-k', type=int, default=0,
                        help='the number of elements that should sum to the target (e.g. 3 for 3-sum).  Any number if not specified')
    args = parser.parse_args()
    n = args.n
    size = args.size
    k = args.k

    t = size*(k if k else n) + 1 # pick target so large that no solution exists
    
    print('%s %s' % (n, t))
    for i in range(n):
        print(random.randint(1, size))
