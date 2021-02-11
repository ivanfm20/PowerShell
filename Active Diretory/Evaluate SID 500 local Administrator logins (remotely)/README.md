# Script to evaluate SID 500 Local Administrator logins (remotely)

This script was developed to remotely query (via Get-WinEvent) logons with the local SID 500 account.

The objective is to evaluate the use of this account to find out if there are systemic dependencies (or even misuse of the local account) for the implementation of LAPS (or for blocks on this account, such as the "Deny network access" privilege)

This script initially asks for a list of the machines, tries to access them, identifies the name of the SID 500 account and evaluates the successful logins of this account (only the successful logins because the failure ones do not bring the SID information) and displays the results in a table, in addition to granting the option to generate a CSV file with the results.

This script evaluates the initial connection to query the Administrator account name by WMI and also evaluates the connection by RPC to connect to the Event Viewer remotely with "Get-WinEvent".

Some considerations about running the script:
- Access to the remote host queries all logs with IDs 4624, 4625 and 4776, and this can bring a large result. As the result is displayed on the Grid, it may be slow to load all items.
- Remote hosts are accessed by WMI to query the administrator user's SID and by RPC to connect to the Event Viewer, for this reason, they may be slow at the time of this connection attempt when access is denied.
- It is recommended to run initially on a small number of machines (10, for example) to evaluate performance, before running on a larger number.