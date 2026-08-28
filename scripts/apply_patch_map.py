import json, os, shutil, sys

vendor_dir = sys.argv[1]
workspace = sys.argv[2]
codename = sys.argv[3]

config_path = f"{workspace}/config/{codename}/patch_map.json"
patches_dir = f"{workspace}/patches/{codename}"

if not os.path.isfile(config_path):
    print(f"ERROR: no config found at config/{codename}/patch_map.json")
    print(f"Run MODE=extract for this codename first to generate it.")
    sys.exit(1)

with open(config_path) as f:
    data = json.load(f)

# Recursively index every file under patches/<codename>/ by its basename,
# so it doesn't matter whether files are flat or nested after a rezip.
found = {}
if os.path.isdir(patches_dir):
    for root, _, files in os.walk(patches_dir):
        for fn in files:
            found.setdefault(fn, os.path.join(root, fn))

for entry in data["files"]:
    fn = entry["filename"]
    target = entry["target"]
    dst = os.path.join(vendor_dir, target)

    if fn not in found:
        print(f"SKIP (no patch file, presumably deleted on purpose): {fn}")
        continue
    if not os.path.isfile(dst):
        print(f"SKIP (target not present in vendor): {target}")
        continue

    src = found[fn]
    before = open(dst, "rb").read()
    shutil.copyfile(src, dst)
    after = open(dst, "rb").read()
    status = "CHANGED" if before != after else "IDENTICAL (no diff)"
    print(f"PATCHED: {target}  <-  patches/{codename}/{os.path.relpath(src, patches_dir)}  [{status}]")
