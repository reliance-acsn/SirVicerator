# SirVicerator
A Windows Service Over-Privilege Enumerator

Penetration Testers have been raising issues regarding service over privilege for a long time but for system admins the task of finding and fixing these vulnerabilities is complex and convoluted.  In a penetration test a consultant may compromise a single instance of a vulnerable service and use the resulting privileges of that service to achieve further onward compromise, this is usually performed in isolation and system admins may be left with a mammoth task upon receiving the report as they will have one example of this over privilege but no way of determining further instances of this within their environment.
This is where the inspiration for this project came from.  All penetration testers hate doing manual and repetitive tasks and as such seek automation to assist in their evidence collection.  For me personally I didn’t like manual collection of services such as Tomcat, SQL Server etc. which had over privilege and thus ‘Sir Vicerator’ was born.


<h2>User Guide - Execution</h2>

The tool only requires the execution policy within PowerShell to be unrestricted to allow it to run.  Additionally, for best results the tool should be run under the context of domain administrator and run on Windows 10, Windows Server 2012 or greater.  Open PowerShell as an administrator by selecting the ‘Run as Administrator’ Option from the right click menu.
 
 <img src="https://user-images.githubusercontent.com/72804004/106904736-71f68700-66f3-11eb-993f-fd4c83facfe8.png">
 
Figure 1 Powershell execution
 
Once PowerShell is running under the administrator context the execution policy can be relaxed using the following command.

<code>Set-ExecutionPolicy -ExecutionPolicy “Unrestricted”</code>

 <img src="https://user-images.githubusercontent.com/72804004/106904833-905c8280-66f3-11eb-9610-3b16dc50ec2e.png">
 
Figure 2 Bypassing Execution Policy in PowerShell
 
<h3>Inputs</h3>

‘Sir Vicerator’ requires a host file to be placed into the ‘C:\Users\$env:Username\’ directory, (User’s home folder) with IP addresses or hostnames one per line.  When running on a penetration test this is easily achievable after server enumeration by exporting hosts from tools such as Metasploit where they have been identified as Windows.
Example:

<img src="https://user-images.githubusercontent.com/72804004/106904928-a8cc9d00-66f3-11eb-8ced-72106a1a6d47.png">

Figure 3 Hosts file containing IP Addresses of Windows hosts to be tested
 
<h2>Runtime</h2>

Once inside PowerShell and the execution policy has been relaxed, the tool can be run by navigating to the folder where the tool is and executing it with the ‘.\SirVicerator.ps1’ command.  Initially the tool prompts for an instance ID to preserve historical results in case this has been run before against the same domain, this functionality then separates the output files of the instance into a new directory.
 
 <img src="https://user-images.githubusercontent.com/72804004/106905113-db769580-66f3-11eb-812b-58ccd1620214.png">
 Figure 4 Setting the Execution Policy to Unrestricted and executing the Application

In the case that no host file can be found ‘SirVicerator’ will create the file and insert the localhost and perform analysis against this host only.



Figure 5 Execution without host file, test conducted against localhost only.
In instances where multiple windows servers have been specified, the tool queries each server within the hosts file extracting the service information and outputting a separate csv file for each host containing all the services running as SYSTEM.
Once the hosts have been queried the tool uses the local data to identify whether any services identified are commonly exploited as part of penetration testing and then outputs the predefined services to the screen as issues.  Additionally, the tool creates a Results.csv file where vulnerable services which were identified, and the hosts which were affected are populated.
 
<img src="https://user-images.githubusercontent.com/72804004/106905310-11b41500-66f4-11eb-84ce-3ec123a6f1ae.png">
Figure 5 Execution with host file, test conducted against multiple servers.

<h3>Detection</h3>

The tool identifies the overprivileged services via the service binary name in the path this is then matched to a friendly name to be displayed onscreen as above.  The following applications have been specified for reporting.
•	Database Servers
  o	MSSQL
  o	Oracle
  o	MySQL
  o	Postgres
  o	MongoDb
  o	FirebirdDb
•	Web Servers
  o Apache
  o	Apache Tomcat
  o	Glassfish
  o	JBoss 

<h3>Outputs</h3>
The tool outputs a number of files from a run cycle; the raw data csv files which have had windows services removed. A results file which contains the filtered results produced by the program.  An error log containing detailed error warnings from the application which are obscured at runtime.

<h4>Output Directories</h4>

<table>
<tr>
  <th>File</th>	
  <th>Description</th>
<tr>
<tr>
  <td>SirVicerator</td>
  <td>Directory containing all output files created by the program</td>
 </tr>
<tr>
  <td>SirVicerator/(instance)	[Optional]</td> 
  <td>instance directory</td>
</tr>
</tr>
  <td>SirVicerator/(instance)/Raw</td>	
  <td>Raw output directory</td>
</tr>
</table>

<h4>Temporary Output Files</h4>
<table>
  <tr>
    <th>File</th>	
    <th>Description</th>
  </tr>
  <tr>
    <td>SirVicerator/(instance)/Files.txt</td>	
    <td>Containing a list of host-service.csv files</td>
  </tr>
  <tr>
    <td>SirVicerator/(instance)/Temp.csv</td>	
    <td>Temporary csv file for stripping out extraneous information before printing the issue to the screen</td>
</table>

<h4>Output Files</h4>

<table>
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
   <td>Hosts.txt</td>
   <td>File containing hosts to be tested</td>
  </tr>
  <tr>
   <td>SirVicerator/(instance)/Results.csv</td>
   <td>Findings from the runtime execution, in csv format</td>
  </tr>
  <tr>
   <td>SirVicerator/(instance)/Errors.txt</td>
   <td>Error Log for the runtime; containing detailed errors encountered </td>
  </tr>
  <tr>
    <td>SirVicerator/(instance)/Raw/(host)-services.csv</td>
    <td>Per host file containing full list of non-windows services</td>
  </tr>
  </table>
