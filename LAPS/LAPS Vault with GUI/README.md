# LAPS Vault with GUI

This script was developed for administrators who want to use the local Administrator account to connect by Terminal Services on the machines, in an environment with passwords managed by Microsoft LAPS.

Using a connection with the local administrator credential (with a random password between machines), it is possible to reduce side attacks of the pass-the-hash type, because if this credential is compromised, access will be restricted only to the host where this user and password configured.

For execution it is necessary to run PowerShell as an Administrator to then execute the script. It is also necessary the Active Directory module of PowerShell, which if not available on the machine can be added as "Features on Demand" on newer versions, or installed with RSAT (https://www.microsoft.com/en-us/download/details.aspx?id=45520).

The recommendation is that the script be run from a secure network host (something like a PAW or hop server/jump server) with source and destination access restrictions and extra security measures.