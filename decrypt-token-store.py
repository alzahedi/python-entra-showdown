from msal_extensions import FilePersistenceWithDataProtection
import os


def get_config_dir():
    import os

    return os.getenv("AZURE_CONFIG_DIR", None) or os.path.expanduser(
        os.path.join("~", ".azure")
    )


config_dir = get_config_dir()
token_cache_path = os.path.join(config_dir, "msal_token_cache.bin")
print(config_dir)

cache = FilePersistenceWithDataProtection(token_cache_path)
content = cache.load()

print("Original content:")
print(content)

hack_content = ""
with open("msal_token_cache-hack.json", "r") as f:
    hack_content = f.read()

cache.save(hack_content)
content = cache.load()

print("Hacked content:")
print(content)

spn_cache_path = os.path.join(config_dir, "service_principal_entries.bin")

spn_cache = FilePersistenceWithDataProtection(spn_cache_path)
spn_cache_content = spn_cache.load()

print("Original SPN content:")
print(spn_cache_content)

hack_spn_content = ""
with open("service_principal_entries-hack.json", "r") as f:
    hack_spn_content = f.read()

spn_cache.save(hack_spn_content)
hack_spn_content = spn_cache.load()

print("Hacked SPN content:")
print(hack_spn_content)
