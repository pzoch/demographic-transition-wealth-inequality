"""Parse a Stata .stpr (Java-serialized Tree) and print the section/child layout."""
import sys
import javaobj.v2 as javaobj

def get_field(obj, name):
    fd = obj.field_data
    for cd, fields in fd.items():
        for fdesc, val in fields.items():
            if fdesc.name == name:
                return val
    raise KeyError(name)

def walk(node, depth=0):
    data = get_field(node, "data")
    children = get_field(node, "children")
    # data is a ProjItem with name/path, or None for root
    if data is None:
        label = "<root>"
        path = ""
    else:
        name = get_field(data, "name")
        path = get_field(data, "path")
        label = name
    indent = "  " * depth
    print(f"{indent}- {label!s}    [path: {path!s}]")
    # children is an ArrayList
    if children is not None:
        for c in children:
            walk(c, depth + 1)

def main(path):
    with open(path, "rb") as f:
        blob = f.read()
    # file has a one-byte 0xFF prefix sometimes? actually magic starts aced0005
    # find magic
    idx = blob.find(b"\xac\xed\x00\x05")
    if idx != 0:
        print(f"note: magic found at offset {idx}, using from there")
        blob = blob[idx:]
    tree = javaobj.loads(blob)
    root = get_field(tree, "rootElement")
    walk(root)

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "outputs_stata_code/__replication_graphs.stpr")
