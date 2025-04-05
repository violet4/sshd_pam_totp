
This project demonstrates the (near) minimum configuration required to set up TOTP in SSHD using PAM.

Most credit goes to Scott Garrett <https://www.technomancer.com/archives/503>

I'm well aware that the secret is generated at image-creation time and reused every time a new container is created from the same image. This was meant to be a quick proof-of-concept. If it bothers you enough, feel free to change your own copy or submit a PR.
