
from heapq import heappush, heappop, heapify
from collections import Counter
import math
import pprint
 
def encode_inner(symb2freq):
    """Huffman encode the given dict mapping symbols to weights"""
    heap = [(wt, i, (sym,), [[sym, ("", 0, 0)]]) for i, (sym, wt) in enumerate(symb2freq.items())]
    heapify(heap)
    while len(heap) > 1:
        lo_w, lo_i, lo_tree, lo_codes = heappop(heap)
        hi_w, hi_i, hi_tree, hi_codes = heappop(heap)
        for pair in lo_codes:
            (s_code, int_code, l) = pair[1]
            pair[1] = (s_code + '0', int_code << 1, l+1)
            assert l+1 <= 16
        for pair in hi_codes:
            (s_code, int_code, l) = pair[1]
            pair[1] = (s_code + '1', (int_code << 1)+1, l+1)
            assert l+1 <= 16
        heappush(heap, (lo_w+hi_w, lo_i, (lo_tree, hi_tree), lo_codes + hi_codes))
    _, _, tree, codes = heap[0]
    return sorted(codes, key=lambda p: (p[1][2], p[1][0])), tree

def encode(values):
    sf = Counter(values)
    return (sf, encode_inner(sf))
 
def disp_huffman(x):
    symb2freq, (huff, tree) = encode(x)
    print("Symbol\tWeight\tCode_s\tCode_i\tLen")
    ltot = 0
    for p in huff:
        (s_code, int_code, l) = p[1]
        ltot += l*symb2freq[p[0]]
        print("%s\t%s\t%s\t%d\t%s" % (p[0], symb2freq[p[0]], s_code, int_code, l))
    print('tot len', ltot, 'avg len', ltot/len(x))
    pprint.pprint(tree)


