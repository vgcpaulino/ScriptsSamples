# Jenkins Metrics Extraction

## Main Description:
This folder contains scripts with samples to create a monitoring solution for Jenkins.

The solution was used to follow the execution of all the Jenkins jobs for a development project, this solution uses:
Jenkins (As the orchestrator).
Jenkins HttpRequest plugin and Jenkins API (To get the job results).
Jenkins Bat plugin (To execute bat commands).
SQL Server (To store and parse the job results).
Grafana (To connect into the SQL Server DB, query and display the dashboards).

The development project uses the TestComplete tool to execute automated tests in the Jenkins Slaves, so part of the Pipeline and SQL DB Schema uses information based on that, but it can be changed for other tests plugins.

## Pipeline Workflow:
- Get all the Job Names running on Jenkins.
- Get all the builds (exciting) for each Job.  
Currently, it's using a time difference to check each job builds will be included. Because the pipeline runs each 4 hours.  
It could be changed to be activated after each job execution as well, reducing the time execution.
- Create the API string to get the information for each Job and Build execution.
- For each item call the Jenkins API and get the JSON each the information.  
When applicable it will check and get the result of the stages (if the Jenkins Job is using Pipeline and not a Freestyle Job) and the results of the tests.  
The information will be added right after being gotten using the bat plugin and executing an SQLCMD command that passes the mandatory information and calls the DB stored procedures.
- After adding all the information into the SQL Server DB, it will use the bat plugin to execute an SQLCMD command that calls the DB stored procedures to process all the information that was added (leaving the JSON parsing for the SQL Server).