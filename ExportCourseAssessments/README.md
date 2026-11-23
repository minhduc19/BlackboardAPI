# Export course assessments

Use PowerShell 5.1 or later. Copy `credentials.template.json` to `credentials.json` in this directory and fill in the Blackboard Learn REST integration's client ID and secret. For a full export, the integration user needs the `course.gradebook.MODIFY` entitlement in the requested courses. Blackboard can return fewer columns and fields to eligible student or observer accounts. Keep the filled-in credentials file local.

Create a UTF-8 `courses.txt` with one course ID per line. Bare IDs are treated as Blackboard course IDs, except internal IDs such as `_123_1`. Use `courseId:`, `externalId:`, or `uuid:` to specify the ID type explicitly. See [courses.example.txt](courses.example.txt).

From this directory, run:

```powershell
.\ExportCourseAssessments.ps1 -CoursesPath .\courses.txt -OutputPath .\assessments.csv
```

Use `-BaseUrl https://learn.example.edu` for a different Learn instance. Use `-CredentialsPath` to read credentials from a different file.

The exporter writes one UTF-8 CSV with a row for each gradebook column returned across all requested courses. The `course` field contains the original input identifier. API fields use a `column.` prefix, and nested object fields have dotted headers such as `column.score.possible` and `column.grading.due`. Literal tildes and dots in field names are escaped as `~0` and `~1`, respectively.

Arrays, including arrays of nested objects such as rubric associations, are stored as compact JSON inside CSV cells. Empty objects are stored as `{}`. The header includes fields found on any page or course. Missing and null fields are blank, and an empty course gets a row with only its course ID.

The exporter follows pagination and writes the CSV after all courses are fetched successfully. It uses `GET /learn/api/public/v2/courses/{courseId}/gradebook/columns`.

[Blackboard Learn REST API reference](https://developer.blackboard.com/portal/displayApi)
