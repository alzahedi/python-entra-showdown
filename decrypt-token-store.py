from msal_extensions import FilePersistenceWithDataProtection
import os

location = os.path.expanduser("~/.azure/msal_token_cache.bin")
cache = FilePersistenceWithDataProtection(location)
content = cache.load()
print(content)
