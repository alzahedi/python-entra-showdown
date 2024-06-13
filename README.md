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

### Prerequisites
1. Setup a VM or dev environment.
2. Make sure you have git installed on the machine.
3. Run [pre req script](./decrypt-token-pre-req.ps1)
4. Arc onboard the machine.
5. Run below command just once to have .azure folder created and populated with defaults
    ```
    az login --service-principal `
    --username <SPN_CLIENT_ID> `
    --password SPN_CLIENT_SECRET `
    --tenant SPN_TENANT_ID 
    ``` 
6. Go inside .azure folder to azureProfile.json file and replace the user name with arc server client id.
7. Create a `.env` file that looks like this:
    ```env
    TENANT_ID=7...7
    ...=...
    ```

### Turn on virtual environment
#

Launch powershell as administrator and run
```python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

#### Run the decrypt store file to have the cache updated.
```
python decrypt-token-store.py
```

#### Turn off virtual environment
```
deactivate
```