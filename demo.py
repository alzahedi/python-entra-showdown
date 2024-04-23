import msal
import os
import requests

from azure.identity import ManagedIdentityCredential
from dotenv import load_dotenv

load_dotenv()

spn_client_id = os.getenv("SPN_CLIENT_ID")
spn_client_secret = os.getenv("SPN_CLIENT_SECRET")
uami_client_id = os.getenv("UAMI_CLIENT_ID")
tenant_id = os.getenv("TENANT_ID")
subscription_id = os.getenv("SUBSCRIPTION_ID")
resource_group = os.getenv("RESOURCE_GROUP")
resource_provider = os.getenv("RESOURCE_PROVIDER")
resource_type =  os.getenv("RESOURCE_TYPE")
resource_name = os.getenv("RESOURCE_NAME")
resource_provider_api_version = os.getenv("RESOURCE_PROVIDER_API_VERSION")

scopes = ["https://management.azure.com/.default"]

# MSAL
#
print(f"Using SPN {spn_client_id} for authentication")
spn_app = msal.ConfidentialClientApplication(
    client_id = spn_client_id,
    client_credential = spn_client_secret,
    authority = "https://login.microsoftonline.com/" + tenant_id
)

# Check cache first
result = spn_app.acquire_token_silent(scopes=scopes, account=None)

# Authenticate if cache is empty
if not result:
    result = spn_app.acquire_token_for_client(scopes=scopes)

print("Token from msal for SPN")
print(result["access_token"])

# Azure AD
#
print(f"Using UAMI {uami_client_id} for authentication")

uami_credential = ManagedIdentityCredential(client_id=uami_client_id)
uami_token = uami_credential.get_token(*scopes)

print("Token from azure.identity for UAMI")
print(uami_token.token)

# Getting ARM object
#
resource_uri = f"subscriptions/{subscription_id}/resourcegroups/{resource_group}/providers/{resource_provider}/{resource_type}/{resource_name}"
full_url = f"https://management.azure.com/{resource_uri}?api-version={resource_provider_api_version}"

print(f"Getting ARM object from {full_url}")

headers = {'Authorization': 'Bearer {}'.format(uami_token.token)}
response = requests.request("GET", full_url, headers=headers)
print(response.json())