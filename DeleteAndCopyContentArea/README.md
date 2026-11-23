#What is this code for
Regular course copy only append content from template into target course. And this code can be used to delete all contents in content area of a course, and then copy content from a template into that course. 
Note: this should be used when Gradebook is empty, ideally before course content is developed. Most suitable for Course Rollover process. 

#How to use
Open file "credentials.template.json", copy in client_id and client_secret, and change the file name into "credentials.json"
Open up powershell in any window computer, go to a folder such as "DeleteAndCopyContentArea".
Run the file using this command: .\RunApi.ps1 -templateCourseId "TEMPLATE_ULTRA_PY_CWI" -targetCourseId "ULTRA_PRACTICE_admindn"

#How does that work
There are three steps involved:
1. Read all contents of a course
2. Delete all content of a course 
3. Copy all content from template into target course. You can adjust what can be copied from template in the file CopyAllCourseContent.ps1

#Future development
1. The code is running one course at a time. We can implement running a list of courses in a file. 
2. Add a new parameter in "credentials.json" to change between Staging and Production. 