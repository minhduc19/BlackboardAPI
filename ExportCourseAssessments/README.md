# Export course assessments

Use PowerShell 5.1 or later. Copy `credentials.template.json` to `credentials.json` in this directory and fill in the Blackboard Learn REST integration's client ID and secret. The integration user needs read access to the requested courses and their content. Keep the filled-in credentials file local.

Create a UTF-8 `courses.txt` with one course ID per line. Bare IDs are treated as Blackboard course IDs, except internal IDs such as `_123_1`. Use `courseId:` or `externalId:` to specify the ID type explicitly. See [courses.example.txt](courses.example.txt).

From this directory, run:

```powershell
.\ExportCourseAssessments.ps1 -CoursesPath .\courses.txt -OutputPath .\assessments.txt
```

Use `-BaseUrl https://learn.example.edu` for a different Learn instance. Use `-CredentialsPath` to read credentials from a different file.

The output is a UTF-8 text file containing a JSON array grouped by course. The script reads paginated course contents and nested folders and exports the full content records for recognized assessment, test, assignment, and survey handlers. Courses with no matching content have an empty `assessments` array. The report is written after all courses are fetched successfully.

Coverage depends on which assessment content and handler types your Learn version and integration expose through the course contents API. [Blackboard Learn REST API reference](https://developer.blackboard.com/portal/displayApi)
