"""Check that each blank-line-separated item of EMITTED is an item of GOLDEN, in order."""
import sys


def chunks(path):
    text = open(path).read()
    return text, [c.strip("\n") for c in text.split("\n\n")]


gtext, g = chunks(sys.argv[1])
etext, e = chunks(sys.argv[2])
it = iter(g)
missing = [c for c in e if not any(c == x for x in it)]
shape = etext.endswith("}\n") and "\n\n\n" not in etext and not etext.endswith("\n\n")
print("\n---\n".join(missing))
good = not missing and shape and len(e) > 1
print("SAMPLE-EQUAL" if good else "SAMPLE-DIFF", sys.argv[2], len(e), "items, shape", shape)
sys.exit(0 if good else 1)
