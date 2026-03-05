# Schema Builder Feedback

## What Aligns Well With the Project

### Split-panel Architecture

> The two-panel layout (left config panel + right live preview) is the correct pattern for a schema builder. It mirrors professional tools like Airtable's field editor and gives immediate visual feedback.

### Schema Preview Table

> The right panel shows a live schema preview with Field Name / Type / Required / Default columns. This is exactly the correct abstraction — it mirrors the structure the back-end will store and gives users a clear mental model.

### Field Type Colour Coding

> Type badges use distinct colours per type: "text" in violet, "datetime" in orange/amber, "number" in purple, "select" in blue. This is a strong UX pattern for data-dense schema tools — types are scannable at a glance.

### Soft Delete & Audit Trail Toggles

> Both optional collection features (soft delete and audit trail) are exposed as clearly labelled toggles with descriptive helper text. These are correctly positioned in the Options section above the field list.

### Field Counter Badge

> The "Fields 4" badge on the section header provides quick context on how many fields have been defined without requiring the user to count manually.

### Collection Name Validation Hint

> "Lowercase letters, numbers, underscores" appears immediately below the collection name input as a constraint hint. This is correct inline guidance without requiring an error state to teach the rule.

### Inline Field Editing

> The left panel shows expanded field editing inline (Display label, Minimum length visible for customer_name). This removes the need for a separate modal — the field expands in context.

### "Entity Diagram" Tab

> The Schema Preview panel has a second tab "Entity Diagram" alongside "Schema Preview". This correctly surfaces the ER diagram view specified in the brief.

### Action Buttons in Footer

> "Save as Draft" (secondary) and "Create Collection" (primary/accent) are correctly placed in the bottom footer bar. The hierarchy is right — the primary action is visually dominant.

## Proposed Improvements

### Left Panel — No "+ Add Field" Button

> There is no visible way to add a new field from the left panel. The only fields visible are those already created. The entry point for the core action of this screen is missing.

### Fix Sidebar Layout

> By default the sidebar may be hidden
> Fix the sidebar
