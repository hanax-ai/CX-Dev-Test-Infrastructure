import requests

API_GATEWAY_URL = "http://192.168.10.39:8000"

def test_root():
    try:
        response = requests.get(f"{API_GATEWAY_URL}/")
        if response.status_code == 200:
            print("✅ API Gateway root `/` is responding")
            print("Response:", response.text)
        else:
            print(f"⚠️ Unexpected status code: {response.status_code}")
            print("Body:", response.text)
    except Exception as e:
        print("❌ Failed to reach API Gateway at root `/`")
        print("Error:", str(e))

if __name__ == "__main__":
    test_root()
