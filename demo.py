import msal
import os

from azure.identity import ManagedIdentityCredential
from dotenv import load_dotenv

load_dotenv()

spn_client_id = os.getenv("SPN_CLIENT_ID")
spn_client_secret = os.getenv("SPN_CLIENT_SECRET")
uami_client_id = os.getenv("UAMI_CLIENT_ID")
tenant_id = os.getenv("TENANT_ID")

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

print("Token from UAMI")
print(result["access_token"])

# Azure AD
#
print(f"Using UAMI {uami_client_id} for authentication")

uami_credential = ManagedIdentityCredential(client_id=uami_client_id)
uami_token = uami_credential.get_token(*scopes)

print("Token from UAMI")
print(uami_token.token)
