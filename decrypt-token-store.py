import json
from dotenv import load_dotenv
from msal_extensions import FilePersistenceWithDataProtection
import os
from jinja_utils import get_template
from token_utils import get_token, decrypt_token

load_dotenv()

## Constants
TOKEN_CACHE_TEMPLATE_FILE_NAME = "msal_token_cache-schema.json"
SERVICE_PRINCIPAL_ENTRIES_TEMPLATE_FILE_NAME = "service_principal_entries-schema.json"

def get_config_dir():
    import os

    return os.getenv("AZURE_CONFIG_DIR", None) or os.path.expanduser(
        os.path.join("~", ".azure")
    )

## Get token cache bin from azure dir
config_dir = get_config_dir()
token_cache_path = os.path.join(config_dir, "msal_token_cache.bin")

cache = FilePersistenceWithDataProtection(token_cache_path)
content = cache.load()

print("Original content:")
print(content)


## Initialize jinja templating and get template files
dir_path = os.path.dirname(os.path.realpath(__file__))
template_dir = f"{dir_path}\\templates\\"
print(template_dir)
token_cache_template = get_template(template_dir, TOKEN_CACHE_TEMPLATE_FILE_NAME)
spn_cache_template = get_template(template_dir, SERVICE_PRINCIPAL_ENTRIES_TEMPLATE_FILE_NAME)

## Get bearer token
token = get_token(scopes=["https://management.azure.com/.default"])

## Decrypt token
decoded_token = decrypt_token(token)

## Fill in values in template file
SPN_CLIENT_ID = decoded_token["appid"]
TENANT_ID = os.getenv("TENANT_ID")
CACHED_AT = decoded_token["iat"]
EXPIRES_ON = decoded_token["exp"]
EXTENDED_EXPIRES_ON = decoded_token["exp"]

token_cache_content = token_cache_template.render(SPN_CLIENT_ID = SPN_CLIENT_ID, TENANT_ID = TENANT_ID, TOKEN = token, 
                          CACHED_AT = CACHED_AT, EXPIRES_ON = EXPIRES_ON, EXTENDED_EXPIRES_ON = EXTENDED_EXPIRES_ON)

cache.save(token_cache_content)
content = cache.load()

print("Changed content:")
print(content)

spn_cache_path = os.path.join(config_dir, "service_principal_entries.bin")

spn_cache = FilePersistenceWithDataProtection(spn_cache_path)
spn_cache_content = spn_cache.load()

print("Original SPN content:")
print(spn_cache_content)
secret = json.loads(spn_cache_content)[0]["client_secret"]
spn_changed_content = spn_cache_template.render(CLIENT_ID = SPN_CLIENT_ID, TENANT_ID = TENANT_ID, CLIENT_SECRET = secret)


spn_cache.save(spn_changed_content)
changed_spn_content = spn_cache.load()

print("Changed SPN content:")
print(changed_spn_content)
