import requests
import streamlit as st

API_URL_JSON = "http://localhost:8000/api/v1/compliance/check"
API_URL_FILE = "http://localhost:8000/api/v1/compliance/check-file"

def send_text_to_api(text: str):
    payload = {
        "document_text": text,
        "rules": {
            "forbidden_keywords": [k.strip() for k in st.session_state.get("keywords", "").split(",") if k.strip()]
        }
    }
    try:
        r = requests.post(API_URL_JSON, json=payload, timeout=60)
        return r.json()
    except Exception as e:
        return {"error": str(e)}

def send_file_to_api(file_path: str):
    files = {"file": open(file_path, "rb")}
    data = {
        "forbidden_keywords": st.session_state.get("keywords", "")
    }
    try:
        r = requests.post(API_URL_FILE, files=files, data=data, timeout=120)
        return r.json()
    except Exception as e:
        return {"error": str(e)}
    finally:
        try:
            files["file"].close()
        except Exception:
            pass
