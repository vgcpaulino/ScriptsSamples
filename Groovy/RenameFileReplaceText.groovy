def originalFilePath = "C:\\Shared\\TestedApps.tcTAs";
def newFilePath = "C:\\Shared\\TestedApps.txt";
def originalValue = "C:\\\\XIMS";
def newValue = "C:\\\\XIMS_25"

// Get the file to be renamed;
def file = new File(originalFilePath);

// Rename the file;
file.renameTo newFilePath

// Get the new file content and replace the values;
file = new File(newFilePath);
def fileText = file.text;

// The "(?i)" is used to ignore the case sensitive;
fileText = fileText.replaceAll("(?i)${originalValue}", newValue);
file.write(fileText);

// Rename the file again;
file = new File(newFilePath);
file.renameTo originalFilePath;
