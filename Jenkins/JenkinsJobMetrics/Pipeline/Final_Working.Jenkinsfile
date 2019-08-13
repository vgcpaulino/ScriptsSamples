
/* ADD BELOW THE FUNCTIONS THAT CAN BE CALLED INSIDE THE PIPELINE */
def getJobBuildList(String jobName){
    def job = getJob(jobName);
    
    def buildList = [];
    job.getBuilds().each{
        def minimumDateTime = returnPrevious5Hours();
        def buildDate = it.getTime();
        
        if (checkIfBuildIsConsider(buildDate, minimumDateTime) == true){
            buildList.push(it.number);
            println('The build WAS INCLUDED because of the execution date! (Job Name: ' + jobName 
                + ' / Build Number: ' + it.number 
                + ' / Build Date: ' + buildDate
                + ' / Minimum Date: ' + minimumDateTime + ')'
            );
        } else {
            println('The build WAS NOT INCLUDED because of the execution date! (Job Name: ' + jobName 
                + ' / Build Number: ' + it.number 
                + ' / Build Date: ' + buildDate
                + ' / Minimum Date: ' + minimumDateTime + ')'
            );
        }
    }
    return buildList;
}

def getJobsBuildUrlList(String jobName, buildList){
    String buildUrl;
    def urlList = [];
    
    int buildListSize = returnListSize(buildList);
    for (int buildIndex = 0; buildIndex < buildListSize; buildIndex++){
        buildUrl = "http://localhost:8080/job/" + jobName + "/" + buildList[buildIndex] + "/api/json";
        String newBuildUrl = buildUrl.replaceAll(' ', '%20');
        urlList.push(newBuildUrl);
    }

    return urlList;
}

def getJsonContent(String link){
    def httpResult = httpRequest authentication: 'userAuth', validResponseCodes: '100:404', url: link;
    return httpResult.getContent();
}

def checkJsonHasTests(String json){
    def index = json.indexOf('com.smartbear.jenkins.plugins.testcomplete.TcSummaryAction');
    if (index >= 0){
        return true;
    }
    return false;
}

def checkJsonHasPipeline(String json){
    def index = json.indexOf('org.jenkinsci.plugins.workflow.job.WorkflowRun');
    if (index >= 0){
        return true;
    }
    return false;
}

def checkJsonHasFreeStyle(String json){
    def index = json.indexOf('hudson.model.FreeStyleBuild');
    if (index >= 0){
        return true;
    }
    return false;
}

/* ADD BELOW THE FUNCTIONS THAT CAN BE USED BY ANOTHER FUNCTION */
def getAllJobNames(){
    def jobs = Jenkins.instance.getAllItems(AbstractItem.class);
    def jobNamesList = [];
    jobs.each{
        jobNamesList.push(it.fullName);
    }
    return jobNamesList;
}

def getJob(String jobName){
    def job = Jenkins.instance.getItem(jobName);
    return job;
}

@NonCPS
def returnPreviousDay(){
    // Get the current date time and remove one day from it;
    def currentDateTime = new Date();
    def minimumDateTime = currentDateTime.previous();
    return minimumDateTime;
}

@NonCPS
def returnPrevious5Hours(){
    // Get the current date time;
    def currentDateTime = new Date();
    
    // Remove 4 hours from it;
    Calendar cal = Calendar.getInstance();
    cal.setTime(currentDateTime);
    cal.add(Calendar.HOUR, -5);
    Date minimumDateTime = cal.getTime();

    return minimumDateTime;
}

@NonCPS
def checkIfBuildIsConsider(buildDate, minimumDateTime){
    def result;
    if (buildDate.after(minimumDateTime)){
        result = true;
    } else {
        result = false;
    } 
    return result;
}

@NonCPS
def returnListSize(list){
    int listSize = list.size();
    return listSize;
}

@NonCPS
def insertJobIntoDB(String jobLevel, String jobName, int buildNumber, String buildUrl, String buildJson){
    String buildUrlReplaced = buildUrl;
    buildUrlReplaced = buildUrlReplaced.replaceAll('%', 'CHAR(37)');
    
    String jsonReplaced = buildJson;
    jsonReplaced = jsonReplaced.replaceAll('"', 'CHAR(34)');
    jsonReplaced = jsonReplaced.replaceAll('$', 'CHAR(36)');
    jsonReplaced = jsonReplaced.replaceAll('%', 'CHAR(37)');
    jsonReplaced = jsonReplaced.replaceAll('\'', 'CHAR(39)');

    bat "       SQLCMD -S 127.0.0.1 -U SA -P SQLServerPass -I -Q \"            USE [JENKINS] EXEC AddBuildExecution '" + jobLevel + "', '" + jobName + "', " + buildNumber + ", '" + buildUrlReplaced + "', '" + jsonReplaced + "'     \"       ";

}

@NonCPS
def processBuildIntoDB(){
    bat "       SQLCMD -S 127.0.0.1 -U SA -P SQLServerPass -I -Q \"            USE [JENKINS] EXEC ProcessPendingBuilds      \"       ";
}

/* ############################################################################################################################################ */
/* ############################################################################################################################################ */
/* ############################################################################################################################################ */
/* ############################################################################################################################################ */

node('master'){
    
    String[] JobNames = [];
    JobNames = getAllJobNames();

    // Execute the Loop into all Jobs from the array inserting the data into the Database;
    for (index = 0; index < JobNames.length; index++){
        def jobName = JobNames[index];
        def buildNumberList = getJobBuildList(jobName);
        def buildUrlList = getJobsBuildUrlList(jobName, buildNumberList);
        int buildListSize = returnListSize(buildNumberList);

        for (int buildIndex = 0; buildIndex < buildListSize; buildIndex++){
            String json = getJsonContent(buildUrlList[buildIndex]);
            insertJobIntoDB('BUILD', jobName, buildNumberList[buildIndex], buildUrlList[buildIndex], json);
            
            if (checkJsonHasPipeline(json)){
                String stagesUrlString = (buildUrlList[buildIndex]).replace('/api/json', '/wfapi/describe');
                String jsonStages = getJsonContent(stagesUrlString);
                insertJobIntoDB('STAGES', jobName, buildNumberList[buildIndex], stagesUrlString, jsonStages);
            }
            
            if (checkJsonHasTests(json)){
                String testUrlStrnig = (buildUrlList[buildIndex]).replace('/api/json', '/TestComplete/api/json');
                String jsonTests = getJsonContent(testUrlStrnig);
                insertJobIntoDB('TESTS', jobName, buildNumberList[buildIndex], testUrlStrnig, jsonTests);
            }
        }
    }

    processBuildIntoDB();
}