# LRN CSV upload

Open Admin → LRN Registry → Upload CSV. Select a file, review the valid-record count and preview, then confirm Import.

Save files as **CSV UTF-8 (comma-delimited)**. Maximum: 5 MB and 10,000 student rows.

```csv
LRN,First Name,Last Name,Middle Name
123456789012,Juan,Dela Cruz,Santos
123456789013,Ana,"Santos, Jr.",
```

- LRNs must be exactly 12 digits. Format the spreadsheet's LRN column as text before entering values. Leading zeros are preserved; scientific notation is rejected because lost digits cannot safely be reconstructed.
- First and last names are required. Middle name is optional. Each name is limited to 150 characters.
- Header names are case-insensitive and support spaces, underscores or hyphens. Required named columns may be reordered. Headerless files must use the example order with three or four columns.
- Quoted commas, escaped double quotes, quoted newlines, Unicode names, UTF-8 BOM, Windows line endings and blank lines are supported.
- The full file is validated before writing. Invalid rows or duplicate LRNs within the file stop the import and show an error; rows are not silently discarded.
- Existing LRNs are skipped, preserving names, registration status and linked-account metadata. This upload does not update existing records.
- Imports run in transactions of up to 100 records. If a later chunk fails, earlier successful chunks remain. Retry the same file: already inserted records will be skipped. Reported additions are confirmed commits, not a promise that an interrupted server request made no changes.
- The importer reads file bytes rather than device paths, so it supports the web picker as well as mobile/desktop pickers.

Verification: CSV parser and import-orchestration regression tests are in `test/lrn_csv_import_test.dart`. Tests use a fake write boundary, not the production database. A real authorized admin upload still needs acceptance testing. No production records are uploaded by the tests.
