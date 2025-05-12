# Agora Token Server

A simple Python server for generating Agora tokens for live streaming.

## Setup

1. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

2. The app.py file already includes default Agora credentials, but you can override them with environment variables:
   ```
   export AGORA_APP_ID=your_app_id
   export AGORA_APP_CERTIFICATE=your_app_certificate
   ```

   On Windows:
   ```
   set AGORA_APP_ID=your_app_id
   set AGORA_APP_CERTIFICATE=your_app_certificate
   ```

3. Run the server:
   ```
   python app.py
   ```

4. Test the server:
   ```
   python test_server.py
   ```

5. Debug token generation:
   ```
   python check_rtc_role.py
   ```

## Troubleshooting

If you encounter issues with the token generation:

1. Make sure you have the correct version of agora-token-builder installed:
   ```
   pip install agora-token-builder==1.0.0
   ```

2. Check that your Agora App ID and App Certificate are correct.

3. Run the check_rtc_role.py script to verify that the token generation works correctly.

4. If you get an error about RtcRole, make sure you're using the correct role value (1 for Publisher).

## API Usage

### Generate Token

**Endpoint:** `POST /generate-token`

**Request Body:**
```json
{
  "channelName": "your_channel_name",
  "uid": 0,
  "role": 1,
  "expirationTimeInSeconds": 3600
}
```

**Response:**
```json
{
  "token": "generated_token_string"
}
```

## Security Considerations

- Keep your Agora App Certificate secure
- Use HTTPS in production
- Consider adding authentication to the token server

## Flutter Integration

In your Flutter app, make sure to update the LiveSessionService with the correct token server URL:

```dart
final String _tokenServerUrl = 'http://192.168.239.58:5000/generate-token';
```

For local testing:
- Android Emulator: Use `http://10.0.2.2:5000/generate-token`
- iOS Simulator: Use `http://localhost:5000/generate-token`
- Physical Device: Use `http://192.168.239.58:5000/generate-token` (or your computer's IP address)
