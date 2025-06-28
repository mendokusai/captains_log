# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NewLog is an Elixir escript tool for generating daily developer logs in markdown format. It manages weekly log directories and automatically archives old weeks while creating new ones.

## Core Architecture

### Main Module (`lib/new_log.ex`)
- **Escript Entry Point**: `main/1` function handles command-line arguments and orchestrates the logging workflow
- **Weekly Management**: Automatically detects when a new week starts and archives the previous week
- **Todo Extraction**: Parses existing log files to extract todos (lines starting with `@ -`) and carries them forward
- **Path Navigation**: Uses `navigate_to_path/1` to locate the target log directory from various starting locations

### Key Data Flow
1. Parse command line options using `OptionParser`
2. Navigate to the target log directory (configured via `LOG_PATH` environment variable)
3. Determine current week vs. existing week to decide workflow:
   - **Same week**: Add new log file to existing current-week directory
   - **New week**: Archive old week to `history/YYYY/week NN/`, create new current-week directory
   - **New year**: Handle year transitions with additional directory creation
4. Extract todos from the most recent log file
5. Generate new log file with template including date and carried-over todos

### Directory Structure
- `current-week-NN/` - Active weekly directory containing daily log files
- `history/YYYY/week NN/` - Archived weekly directories organized by year
- `special/` - Special log entries (via `--special` flag)
- Log files follow naming pattern: `dNNNNN.md` (e.g., `d01234.md`)

## Common Development Commands

### Build and Run
```bash
# Build the escript
mix escript.build

# Run the built escript
./new_log

# Run with options
./new_log --help
./new_log --date "2021-01-01"
./new_log --debug --add
```

### Testing
```bash
# Run all tests
mix test

# Run specific test
mix test test/new_log_test.exs
```

### Development
```bash
# Get dependencies
mix deps.get

# Compile
mix compile

# Format code
mix format
```

## Environment Configuration

Set `LOG_PATH` environment variable to specify the target directory for logs:
```bash
export LOG_PATH="/path/to/your/dev_log"
```

## Command Line Options

- `--help` / `-h`: Show help dialog
- `--date` / `-d`: Generate log for specific date (format: "YYYY-MM-DD")
- `--debug` / `-z`: Enable debug mode
- `--add` / `-a`: Add new file to current week (used with debug)
- `--new` / `-n`: Create new directory with specified name
- `--special` / `-s`: Save file in special directory
- `--keep` / `-k`: Preserve files when archiving (don't delete current week)

## Testing Notes

- Tests use the `priv/` directory for test fixtures
- Tests include cleanup with `on_exit/1` callbacks
- Navigation tests verify the path resolution logic works from different starting directories
- Week transition tests verify archiving and new directory creation