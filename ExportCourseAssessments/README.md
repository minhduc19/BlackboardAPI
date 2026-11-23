# Export course assessments

Use PowerShell 5.1 or later. Copy `credentials.template.json` to `credentials.json` in this directory and fill in the Blackboard Learn REST integration's client ID and secret. For a full export, the integration user needs the `course.gradebook.MODIFY` entitlement in the requested courses. Blackboard can return fewer columns and fields to eligible student or observer accounts. Keep the filled-in credentials file local.

Create a UTF-8 `courses.txt` with one course ID per line. Bare IDs are treated as Blackboard course IDs, except internal IDs such as `_123_1`. Use `courseId:`, `externalId:`, or `uuid:` to specify the ID type explicitly. See [courses.example.txt](courses.example.txt).

From this directory, run:

```powershell
.\ExportCourseAssessments.ps1 -CoursesPath .\courses.txt -OutputPath .\assessments.txt
```

Use `-BaseUrl https://learn.example.edu` for a different Learn instance. Use `-CredentialsPath` to read credentials from a different file.

The output is a UTF-8 text file containing a JSON array grouped by course. Each course's `assessments` array contains every column returned by `GET /learn/api/public/v2/courses/{courseId}/gradebook/columns`, including manual and calculated columns when Blackboard returns them. The exporter follows pagination, preserves the returned fields, and writes the report after all courses are fetched successfully. Courses with no returned columns have an empty array.

[Blackboard Learn REST API reference](https://developer.blackboard.com/portal/displayApi)
