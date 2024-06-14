# Python Entra ID showdown

## Running demo project

A simple project to mess around with the hodge podge of Entra ID SDKs for Python

Create a `.env` file that looks like this:

```env
SPN_CLIENT_ID=e...7
SPN_CLIENT_SECRET=X...d
UAMI_CLIENT_ID=a...f
TENANT_ID=7...7
...=...
```

#### Get Git directory

```powershell
$GIT_ROOT = git rev-parse --show-toplevel
cd "$GIT_ROOT"
```

#### Turn on virtual environment
#

```python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

```
#### Run Demo
#
```python 
python demo.py
```
#### Turn off virtual environment
```
deactivate
```

# Running decrypt token store

Decrypt token store is a small utility project to hydrate az cli token cache with token from HIMDS.

### Prerequisites
1. Setup a Hyper-VM or dev environment.
2. Make sure you have git installed on the machine.

### Launch project
#
1. Open up a powershell window in administrator mode.
2. Go to the cloned repo root directory.
3. Run the below [script](./token-persistor.ps1)

```
.\token-persistor.ps1 -SPN_CLIENT_ID <SPN_CLIENT_ID> `
		      -SPN_CLIENT_SECRET <SPN_CLIENT_SECRET> `
		      -TENANT_ID <TENANT_ID> `
              -SUBSCRIPTION_ID <SUBSCRIPTION_ID> `
		      -RESOURCE_GROUP_NAME <RESOURCE_GROUP_NAME> `
		      -LOCATION <AZURE REGION>
```

The script installs few dependencies like vscode, python. 
It onboards the machine to arc, gets a token from arc. It sets up python virtual environment, installs a bunch of dependencies and calls [decrypt-token-store.py](./decrypt-token-store.py) python script to manually hydrate the az cli token cache with token from arc.