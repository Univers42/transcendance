# SQL Norm

In order to normalize SQL code style in our project, we should use
the linter within the sqlfluff tool (which is a standard in the industry)
to check our .sql files.

## How to use it:

```bash
sqlfluff lint --dialect postgres <your_file.sql>
```
## Config file

.sqlfluff file defines rules. More can be added or updated.

```bash
[sqlfluff]
dialect = postgres
# Exclude rules
exclude_rules = L031

[sqlfluff:indentation]
tab_space_size = 4

[sqlfluff:layout:type:comma]
line_position = trailing

[sqlfluff:rules:capitalisation.keywords]
capitalisation_policy = upper

[sqlfluff]
dialect = postgres
large_file_skip_byte_limit = 50000

```
## Automathic fix:

SQLFluff can automatically rewrite your file to fix almost all formatting errors.

Instead of lint, just run fix:

```bash
sqlfluff fix <your_file.sql>
```

It will ask you to confirm.
