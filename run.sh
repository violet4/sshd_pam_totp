# !/bin/bash
podman run -it --rm --name ssh-totp-container -p 2222:22 --replace ssh-pam-totp
