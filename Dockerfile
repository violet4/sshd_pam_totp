# https://www.technomancer.com/archives/503

FROM ubuntu:22.04

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server \
    oathtool \
    libpam-oath \
    qrencode \
    sudo \
    vim-common \
    nano && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /run/sshd /etc/oath

# Create a test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:password" | chpasswd

# Generate TOTP secret for testuser
RUN secret=$(openssl rand -hex 15) && \
    base32_secret=$(echo -n "$secret" | xxd -r -p | base32) && \
    echo "HOTP/T30 testuser - $secret" > /etc/oath/users.oath && \
    echo "Secret for TOTP: $secret" > /root/totp_secret.txt && \
    chmod 600 /etc/oath/users.oath && \
    echo "otpauth://totp/testuser@ssh-container?secret=$base32_secret&issuer=SSH" | qrencode -o /root/totp_qr.png
    # echo "HOTP/T30/6 testuser - $secret" > /etc/oath/users.oath && \


# Configure PAM for SSH
# TODO this must be: under the line that reads “@include common-account“:
# TODO: window should be reduced to.. maybe 1-2..
RUN echo "auth requisite pam_oath.so usersfile=/etc/oath/users.oath window=2 digits=6" >> /etc/pam.d/sshd

# Configure SSH
RUN sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'AuthenticationMethods keyboard-interactive:pam' >> /etc/ssh/sshd_config && \
    echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'cat /root/totp_secret.txt' >> /start.sh && \
    echo 'echo "SSH TOTP container started. Use this command to copy the QR code to your host:" ' >> /start.sh && \
    echo 'echo "podman cp $(hostname):/root/totp_qr.png ./totp_qr.png"' >> /start.sh && \
    echo 'echo "Connect with: ssh -p 2222 testuser@localhost"' >> /start.sh && \
    echo 'echo "Password: password"' >> /start.sh && \
    echo 'echo "After password, you will be prompted for TOTP code from your authenticator app"' >> /start.sh && \
    echo '/usr/sbin/sshd -D' >> /start.sh && \
    chmod +x /start.sh
# we can add -d or -dd to sshd for debug, but then failed connects and logouts lead to shutdown

    # echo 'service ssh start' >> /start.sh && \
    # echo 'sleep infinity' >> /start.sh && \
#
# Expose SSH port
EXPOSE 22

# Start SSH server
ENTRYPOINT ["/start.sh"]
