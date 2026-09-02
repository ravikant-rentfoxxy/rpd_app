# RPD Flutter app

Field app from the RPD screen deck. GetX for state and routing, Hive for local storage, Hindi / English / Bhojpuri.

## What it does

- Language is chosen first and saved on the device
- OTP sign-in against the local Express API (`9876543210` / `123456`)
- Nearby booths are fetched with the phone lat/long, stored in Hive, then listed from the local box
- Home, work ledger, recruits, tasks, membership card, activity capture, sync queue

## Run

Start the backend first (`~/Desktop/rpd_backend`).

```bash
cd ~/Desktop/rpd_app
flutter pub get
flutter run
```

Set the local API in `assets/env` (the app cannot load a `.env` dotfile as an asset):

```
API_BASE_URL=http://127.0.0.1:4000
```

On the Android emulator, `127.0.0.1` is rewritten to `10.0.2.2` automatically. On a physical phone use your computer LAN IP. Do a full restart after changing `assets/env`.

OTP is the value of `OTP_DEV_CODE` in `rpd_backend/.env`. The app does not prefill it — type that code on the verify screen.
