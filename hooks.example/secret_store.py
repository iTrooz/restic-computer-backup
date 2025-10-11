#!/usr/bin/env python3
import secretstorage
import yaml
import base64
import sys
import os

bus = secretstorage.dbus_init()
ALL_COLLECTIONS = []

def try_into_string(b: bytes) -> str | None:
    try:
        s = b.decode("utf-8")
        if s.isprintable():
            return s
        return None
    except UnicodeDecodeError:
        return None

for collection in secretstorage.get_all_collections(bus):
    try:
        collection.unlock()
    except Exception:
        pass
    coll_secrets = []
    ALL_COLLECTIONS.append({"label": collection.get_label(), "items": coll_secrets})
    
    for item in collection.get_all_items():
        secret = {"label": item.get_label(), "attributes": item.get_attributes() or {}}
        coll_secrets.append(secret)
        try:
            secret_data = item.get_secret()
        except Exception:
            secret_data = None
        
        # Store as string or base64
        if secret_data is None:
            secret["strdata"] = None
        else:
            s = try_into_string(secret_data)
            if s is None:
                secret["b64data"] = base64.b64encode(secret_data).decode("ascii")
            else:
                secret["strdata"] = s

# Print as YAML
dumped = yaml.safe_dump({"collections": ALL_COLLECTIONS}, sort_keys=False)
if len(sys.argv) > 1 and sys.argv[1] == "DUMP":
    print(dumped)
else:
    script_folder = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(script_folder, "../", "tmp/" "secret_store.yaml"), "w") as f:
        f.write(dumped)
