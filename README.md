# Python Entra ID showdown

A simple project to mess around with the hodge podge of Entra ID SDKs for Python

Create a `.env` file that looks like this:

```env
SPN_CLIENT_ID=e...7
SPN_CLIENT_SECRET=X...d
UAMI_CLIENT_ID=a...f
TENANT_ID=7...7
```

Run:

```powershell
$GIT_ROOT = git rev-parse --show-toplevel
cd "$GIT_ROOT"

# Turn on virtual environment
#
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Run Demo
#
python demo.py

# Turn off virtual environment
#
deactivate
```