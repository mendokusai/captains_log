# CaptainsLog

A command-line tool for maintaining daily developer logs in markdown format with automatic weekly organization and todo carry-over.

## Features

- **Daily Log Creation** - Generate timestamped markdown files for daily entries
- **Automatic Organization** - Organizes logs by week with automatic archiving
- **Todo Carry-over** - Extracts incomplete todos from previous logs
- **Smart Archiving** - Automatically archives completed weeks to dated folders
- **Week-aware** - Handles year transitions and week calculations properly

## Prerequisites

- Elixir 1.11 or higher
- Mix build tool

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd captains_log
   ```

2. Install dependencies and build the executable:
   ```bash
   mix deps.get
   mix escript.build
   ```

3. Set up your environment variables:
   ```bash
   cp .envrc.example .envrc
   # Edit .envrc to set your LOG_PATH
   ```

## Configuration

This is built using [direnv](https://direnv.net/)

Create a `.envrc` file (or add to your shell profile) with:

```bash
export LOG_PATH="Developer/dev_log"
```

The tool will create the directory structure automatically on first run:
```
Developer/dev_log/
├── current-week-26/
│   ├── d00101.md
│   ├── d00102.md
│   └── ...
├── history/
│   └── 2025/
│       ├── week 01/
│       ├── week 02/
│       └── ...
└── special/
```

## Usage

### Basic Usage

Create a new log entry for today:
```bash
./captains_log
```

### Command Line Options

```bash
./captains_log --help                    # Show help dialog
./captains_log --date "2025-01-15"      # Create log for specific date
./captains_log --debug --add             # Add file to current week (debug mode)
./captains_log --new "project-notes"     # Create new directory
./captains_log --special "meeting-notes" # Save to special directory
./captains_log --keep                    # Keep files when archiving
```

### Example Workflow

1. **First run** - Creates directory structure and initial log:
   ```bash
   ./captains_log
   # Creates: Developer/dev_log/current-week-26/d00101.md
   ```

2. **Daily use** - Adds new log to current week:
   ```bash
   ./captains_log
   # Creates: Developer/dev_log/current-week-26/d00102.md
   ```

3. **New week** - Automatically archives previous week and starts fresh:
   ```bash
   ./captains_log  # On Monday of new week
   # Archives: current-week-26/ → history/2025/week 26/
   # Creates: current-week-27/d00103.md
   ```

## Log File Format

Each log file includes:
- Timestamped header with day, date, and year
- Carried-over todos from previous logs (marked with `@ -`)
- Space for daily notes and updates

Example log file (`d00101.md`):
```markdown
# d00101.md

*Monday, June, 30, 2025*

@ To complete:
@ - Fix navigation bug
@ - Update documentation
@ - Review pull requests

---

```

## Development

### Running Tests
```bash
mix test
```

### Code Formatting
```bash
mix format
```

### Building
```bash
mix escript.build
```

## How It Works

1. **Week Detection** - Calculates current week number (1-52) based on ISO week standards
2. **Directory Management** - Maintains `current-week-XX` for active logs and archives completed weeks
3. **Todo Extraction** - Scans previous logs for lines starting with `@ -` and carries them forward
4. **Path Navigation** - Uses `File.cd("..")` to navigate from project directory to target location

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Run `mix test` and `mix format`
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Think really hard, _do you actually want to suggest a change?_
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Again, do you really want to make a pull request? **Just fork your own.**
7. _sigh_, Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).


