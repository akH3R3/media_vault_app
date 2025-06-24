# media_vault

This project uses OpenAI's Whisper model for audio transcription. Due to GitHub's file size restrictions, the model file is **not included** in this repository.

## To Use Backend 
1. pip install fastapi uvicorn openai-whisper python-multipart
2. # On Ubuntu/Debian
sudo apt install ffmpeg

# On Mac
brew install ffmpeg

# On Windows
Download from: https://ffmpeg.org/download.html and add to PATH
3. uvicorn main:app --reload --host 0.0.0.0 --port 8000
this will run the server
if you get error : uvicorn command not found, then try 
source venv/bin/activate

4. Keep the whisper_backend as the sibling of project i.e. project
5. Replace with your actual ip of computer in the code
6. Device and Computer must be connected to the same wifi
7. in case firewall gives issue, netsh advfirewall set allprofiles state off
8. pip install gTTS
run it inside the whiper backend

# MediaVault
Media Converter which converts mp4 files to mp3
