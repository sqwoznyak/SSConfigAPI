from fastapi import FastAPI, HTTPException,Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from urllib.parse import urlparse
import base64

app = FastAPI()

def decode_base64(data):
    data += '=' * (-len(data) % 4)
    return base64.urlsafe_b64decode(data).decode('utf-8')

def parse_ss_url(ss_url):
    parsed_url = urlparse(ss_url)
    if parsed_url.scheme != 'ss':
        print("Invalid URL scheme.")
        return None

    try:
        decoded_user_info = decode_base64(parsed_url.username)
        method_cipher, password = decoded_user_info.split(':', 1)
    except (base64.binascii.Error, ValueError) as e:
        print(f"Error parsing user info: {e}")
        return None

    if not parsed_url.hostname or not parsed_url.port:
        print("Invalid host or port.")
        return None

    config = {
        "server": parsed_url.hostname,
        "server_port": parsed_url.port,
        "password": password,
        "method": method_cipher
    }

    return config

def get_config_by_id(user_id):
    ss_url = "ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpIRWlobVQxdzBqTWNJalF3N3VNTmFR@109.206.241.37:56366/?outline=1" # Здесь вытащить из БД
    return parse_ss_url(ss_url)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def force_https(request: Request, call_next):
    if request.url.scheme != "https":
        url = request.url.replace(scheme="https", netloc=f"{request.url.hostname}:443")
        return RedirectResponse(url, status_code=307)
    return await call_next(request)

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/key")
async def get_connect_data():
    data = get_config_by_id(123)
    if data is None:
        raise HTTPException(status_code=404, detail="Configuration not found")
    return data
