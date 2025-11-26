# CSV to Resource Exporter

A Godot addon that simplifies the process of converting CSV data into Godot Resources (`.tres`). This tool allows you to map CSV columns to resource properties, generate strongly-typed GDScript classes, and bulk export resources. Mainly thought for gamejams or prototypes where you want to program and design at te same time!


## Usage Guide

### Step 1: Load CSV
Click the **Browse** button next to "CSV:" to select your source `.csv` file. The tool will automatically parse the file and attempt to guess the data types for each column.

### Step 2: Configure Variables
Once loaded, each column from your CSV will appear as a variable row.
*   **Name**: The name of the property in the generated resource.
*   **Type**: Select the data type (String, int, float, bool, PackedStringArray, Name).
	*   *Note*: The "Name" type is special. It uses the value in this column to name the generated `.tres` file.
*   **Include?**: Uncheck this if you don't want this column to be part of the exported resource.
*   **Extra**: Used for `PackedStringArray` to specify the separator (e.g., `;` or `,`).

### Step 3: Preview & Class Name
The **Preview Code** panel shows the GDScript that will be generated.
*   You can manually edit this code.
*   **Important**: Change the `class_name` to something unique for your resource (e.g., `class_name ItemData`). The tool will use this name for the generated script file.

### Step 4: Templates
You can save your variable configurations as templates to reuse them later.
*   **Save Template**: Click to save the current configuration.
*   **Load Template**: Select a saved template from the dropdown to instantly apply types and settings.

### Step 5: Export Options
Choose what you want to generate:
*   **Gen Resources**: If checked, generates the actual `.tres` resource files for each row in the CSV. The base class script (`.gd`) is **always** generated/updated.

### Step 6: Export
1.  Select an **Export Path** (folder) where the files will be saved.
2.  Click **Export**.
3.  The tool will generate the script and/or resources and refresh the FileSystem.

## Features

*   **Auto Type Estimation**: Attempts to guess if a column is an int, float, bool, or array.
*   **Custom Class Names**: Uses your defined `class_name` for the script filename.
*   **Templates**: Save and load configurations for different CSV types.
*   **Selective Export**: Choose to generate only the script, only the resources, or both.
*   **Progress Feedback**: Visual progress bar for large exports.
