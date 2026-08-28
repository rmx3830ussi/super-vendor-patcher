import json, os, sys

vendor_etc_dir = sys.argv[1]   # e.g. $WORK/vendor/etc
codename = sys.argv[2]
workspace = sys.argv[3]

files = sorted(f for f in os.listdir(vendor_etc_dir) if f.startswith("fstab."))

data = {
    "codename": codename,
    "files": [{"filename": f, "target": f"etc/{f}"} for f in files]
}

out_dir = f"{workspace}/config/{codename}"
os.makedirs(out_dir, exist_ok=True)
with open(f"{out_dir}/patch_map.json", "w") as f:
    json.dump(data, f, indent=2)

print(f"Generated config/{codename}/patch_map.json with {len(files)} entries")
