from azure.identity import ManagedIdentityCredential
import jwt

def get_token(scopes, client_id = None):
    """
    Returns bearer token for client id and scopes
    """
    uami_credential = ManagedIdentityCredential()
    if client_id != None:
        uami_credential = ManagedIdentityCredential(client_id= client_id)
    uami_token = uami_credential.get_token(*scopes)

    print("Token from azure.identity for UAMI")
    #print(uami_token.token)
    return uami_token.token

def decrypt_token(token):
    """
    Decrypts a token using jwt
    """
    decoded = jwt.decode(token, options={"verify_signature": False})
    #print(decoded)
    return decoded

