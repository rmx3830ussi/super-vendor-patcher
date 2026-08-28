import json, os, shutil, sys

vendor_dir = sys.argv[1]
workspace = sys.argv[2]

with open(f"{workspace}/config/patch_map.json") as f:
    mapping = json.load(f)

for entry in mapping:
    src = f"{workspace}/{entry['source']}"
    dst = f"{vendor_dir}/{entry['target']}"
    if not os.path.isfile(src):
        print(f"SKIP (no patch file): {entry['source']}")
        continue
    if not os.path.isfile(dst):
        print(f"SKIP (target not present in vendor): {entry['target']}")
        continue
    before = open(dst, "rb").read()
    shutil.copyfile(src, dst)
    after = open(dst, "rb").read()
    status = "CHANGED" if before != after else "IDENTICAL (no diff)"
    print(f"PATCHED: {entry['target']}  <-  {entry['source']}  [{status}]")
