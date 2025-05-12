from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import time
from dotenv import load_dotenv
from agora_token_builder import RtcTokenBuilder

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Get Agora credentials from environment variables
AGORA_APP_ID = os.environ.get('AGORA_APP_ID')
AGORA_APP_CERTIFICATE = os.environ.get('AGORA_APP_CERTIFICATE')

# Validate that required environment variables are set
if not AGORA_APP_ID or not AGORA_APP_CERTIFICATE:
    raise ValueError("Missing required environment variables: AGORA_APP_ID and AGORA_APP_CERTIFICATE must be set in .env file or environment")

@app.route('/generate-token', methods=['POST'])
def generate_token():
    try:
        data = request.json
        
        # Validate request data
        if not data or 'channelName' not in data:
            return jsonify({'error': 'Channel name is required'}), 400
            
        channel_name = data['channelName']
        uid = data.get('uid', 0)
        role = data.get('role', 1)  # 1 is the value for Publisher role
        expiration_time_in_seconds = data.get('expirationTimeInSeconds', 3600)  # Default: 1 hour
        
        # Calculate privilege expired timestamp
        current_timestamp = int(time.time())
        privilege_expired_ts = current_timestamp + expiration_time_in_seconds
        
        # Build token
        token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE,
            channel_name,
            uid,
            role,
            privilege_expired_ts
        )
        
        return jsonify({'token': token})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
