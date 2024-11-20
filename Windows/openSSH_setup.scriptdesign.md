# Scripting SSH Login setup in windows
[Open in Github](https://github.com/Inteleweb/public_scripts/blob/main/Windows/openSSH_setup.scriptdesign)

> [!Warning]
> Windows has different settings/locations for server vs Desktop so we need to be careful


Spec - Detects scenario 
Makes assumptions where almost certain - otherwises asks
Configures SSH
Can be run in silent mode

1. First we identify if we are on a server or desktop
    Store the result in a variable
2. Save username in a variable

- Enable OpenSSH Server if not enabled
	- Verify
- Set OpenSSH Server to start automatically

### Firewall
- Ask user what port to use (default 22)
	- Validate input (1-65535) using regex
	- Ensure when run in silent mode it doesn't ask for input and defaults to 22
	- modify SSH config file
- Allow SSH traffic through Windows Firewall on specified port

### Key Management
- Ask user if they want to use a pre-existing key or generate a new one
	- If pre-existing key: ask user to paste key or path to key
	    - Possibly parse file for multiple keys
		- Possibly verify key is valid
- 



Notes:

[@ajf8729](https://github.com/ajf8729) says use the built in OpenSSH Server for windows (updates can break the MSI installed version)

TODO: Consider including [Harden-Windows-SSH](https://github.com/JuliusBairaktaris/Harden-Windows-SSH)