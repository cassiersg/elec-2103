
WARNING_STR = '// DO NOT EDIT - file generated by game/gen_huffman.py\n'
CASE_STR = 'case 0x{:x}: code = 0x{:03x}; n_bits = {:2}; break;'

def generate_huffman_encoder(codes, filename):
    case_strs = []
    for sym, (code_str, code_int, n_bits) in codes:
        case_strs.append(CASE_STR.format(sym, code_int, n_bits))
    inc_color = '\n'.join(case_strs)
    with open(filename, 'w') as f:
        f.write(WARNING_STR + inc_color + '\n')

DECODE_IF_STR = {
    'C': 'if ((code >> {}) & 0x1) {{\n',
    'sv': 'if (code[{}]) begin\n',
}
DECODE_ELSE_STR = {
    'C': '} else {\n',
    'sv': 'end else begin\n',
}
DECODE_ENDBLOCK_STR = {
    'C': '}',
    'sv': 'end',
}
DECODE_ASSIGN_STR = {
    'C': 'decoded = 0x{:x};\n{}code_len = {};',
    'sv': "decoded = 32'h{:x};\n{}code_len = 8'd{};",
}
# genenrate decoding C code colors
def gen_decode_tree(tree, r_level, lang):
    indent = r_level*' '
    if len(tree) == 2:
        t0, t1 = tree
        return (indent + DECODE_IF_STR[lang].format(r_level) +
                gen_decode_tree(t1, r_level+1, lang) +
                '\n' + indent + DECODE_ELSE_STR[lang] +
                gen_decode_tree(t0, r_level+1, lang) +
                '\n' + indent + DECODE_ENDBLOCK_STR[lang])
    elif len(tree) == 1:
        res, = tree
        return indent + DECODE_ASSIGN_STR[lang].format(res, indent, r_level)
    else:
        raise ValueError(tree)

def generate_huffman_decoder(tree, filename, lang='C'):
    with open(filename, 'w') as f:
        f.write(WARNING_STR + gen_decode_tree(tree, 0, lang) + '\n')

