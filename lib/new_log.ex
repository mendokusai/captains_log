defmodule NewLog do

  @target_from_loc Application.fetch_env!(:new_log, :path)
  @syd_shift 39_600 # 11 hours * 60 minutes * 60 seconds
  @file_num_length 5 # d12345.md

  @moduledoc """
  Documentation for `NewLog`.
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  There are three main pathways:
  A. Same week
  B. (New) Week is ahead of previous week by 1.
  C. Debug zone
  D. Outlier case (usually end of the year).

  A. Same week should just increment the file number and make a new file. Easy.
  B. A bit more involved:
    - make a new archive dir in +history+,
    - move previous week to the file,
    - create a new +current week+ folder at top-level.
    - increment file number and make a new file.
  C. To be developed, but should handle all options via option flag/testing.
  D. End of the year always exposes issues. I blame the egg nog. Proper testing should aleviate future issues.
  """
  @options [
    switches: [
      new: :string,
      special: :string,
      keep: :boolean,
      add: :boolean,
      date: :string,
      debug: :boolean,
      help: :boolean
    ],
    aliases: [
      h: :help,
      z: :debug,
      d: :date,
      n: :new,
      s: :special,
      k: :keep,
      a: :add
    ]
  ]

  @days_of_the_week %{
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday",
    7 => "Sunday"
  }

  @months %{
    1 => "January",
    2 => "February",
    3 => "March",
    4 => "April",
    5 => "May",
    6 => "June",
    7 => "July",
    8 => "August",
    9 => "September",
    10 => "October",
    11 => "November",
    12 => "December",
  }

  def main(args) do
    with {opts, _raw_args, _} <- OptionParser.parse(args, @options),
         #get date - in UTC, and then offset to SYD TZ.
         datetime <- get_local_time(opts[:date]),
         # TOP [".DS_Store", "test", "current-week-53", "special", "history"]
         {:ok, directory_contents} <- File.ls(@target_from_loc),
         # find current_directory - should only be one.
         current_week_str <- target_current_week(directory_contents),
         # isolate current_week number from file name.
         stale_week_num <- get_week_number(current_week_str),
         # find current week num from datetime.
         current_week_num <- current_week(datetime),

         # latest log file name
         latest_log_file <- get_latest_log_file(current_week_str),
         # get file contents
         {:ok, log_string_data} <- get_file_data(latest_log_file, current_week_str),
         # get todos
         todo_list <- get_todos(log_string_data),
         # get latest log number
         newest_file_num <- get_latest_log_num(latest_log_file),
         # construct +next+ log number
         new_log_filename <- new_file_name(newest_file_num) do
      cond do
        opts[:help] -> render_help_dialog()

        opts[:debug] ->
          if opts[:add] do
            # add file to new to existing current week
            current_path = path(current_week_str)
            template = template(new_log_filename, datetime, todo_list)
            add_file(current_path, new_log_filename, template)
          end

          if opts[:new] |> is_binary do
            add_new_dir(opts[:new])
          end

        current_week_num == stale_week_num ->
          # generate template
          template = template(new_log_filename, datetime, todo_list)
          # path to current week
          path(current_week_str)
          # save template to current directory
          |> add_file(new_log_filename, template)

        current_week_num == 0 || current_week_num > stale_week_num ->
          if current_week_num == 0 do
            IO.puts "Happy new year!"
          end
          # old week path
          existing_path = path(current_week_str)
          # archive path (to save to)
          archive_path = build_archive_folder_path(datetime, stale_week_num)
          # make archive folder
          File.mkdir!(archive_path)
          # copy files from old to new location
          File.cp_r!(existing_path, archive_path)
          # delete old current directory
          {:ok, _f} = delete_stale_current_dir(current_week_str, opts)
          # make new 'current' dir for this week
          {:ok, new_dir} = build_new_week_folder(current_week_num)
          # generate template
          template = template(new_log_filename, datetime, todo_list)
          # save template to new directory
          add_file(new_dir, new_log_filename, template)
        true ->
          IO.puts "An unknown case occured."
      end
    else
      error -> IO.inspect(error, label: "Error")
    end
  end

  def get_todos(string_data) do
    string_data
    |> String.split("\n")
    |> Enum.filter(&(String.match?(&1, ~r/^@ -/))) # get rows with '@ - foo'
    |> Enum.map(&(String.split(&1, "@ - ", trim: true)))
    |> List.flatten
  end

  def get_file_data(nil, _parent_dir), do: {:ok, ""}
  def get_file_data(file_name, parent_dir) do
    path([parent_dir, file_name])
    |> File.read
  end

  def format_date(dt) do
    day = Map.get(@days_of_the_week, dt.calendar.day_of_week(dt.year, dt.month, dt.day))
    month = Map.get(@months, dt.month)
    "#{day}, #{month}, #{dt.day}, #{dt.year}"
  end

  def build_archive_folder_path(datetime, week_number) do
    num = if week_number < 10 do
            "0#{week_number}"
          else
            week_number
          end
    path(["history", "#{datetime.year}", "week #{num}"])
  end

  def format_todos(list) do
    Enum.map(list, fn i -> "@ - #{i}\n" end)
  end

  def add_file(path, file_name, template) do
    path(file_name, path)
    |> File.write(template)
  end

  def new_file_name(last_num) do
    new_num = last_num + 1 |> Integer.to_string
    zero_count = @file_num_length - String.length(new_num)
    zpad = Enum.map(1..zero_count, fn _ -> "0" end) |> Enum.join
    "d#{zpad}#{new_num}.md"
  end

  # only happens when there's no previous week file.
  def get_latest_log_num(nil), do: 100
  def get_latest_log_num(dir_name_str) do
    dir_name_str
    |> String.split([".md", "d"], trim: true)
    |> List.first
    |> String.to_integer
  end

  def get_latest_log_file(dir_name) do
    path(dir_name)
    |> File.ls!
    |> Enum.sort
    |> List.last
  end

  def delete_stale_current_dir(nil, _opts), do: :ok
  def delete_stale_current_dir(dir_name, opts) do
    if opts[:keep] do
      {:ok, "Kept the files, dawg"}
    else
      File.rm_rf(path(dir_name))
    end
  end

  def get_week_number(week_string) do
    [_current, _week, num_str] = String.split(week_string, "-")
    String.to_integer(num_str)
  end

  def get_local_time(nil) do
    DateTime.utc_now
    |> DateTime.add(@syd_shift, :second)
  end

  def get_local_time(string_date) do
    {:ok, datetime_utc, _offset} = "#{string_date}T00:00:00Z"
                                   |> DateTime.from_iso8601
    DateTime.add(datetime_utc, @syd_shift, :second)
  end

  def target_current_week(contents) do
    contents
    |> Enum.filter(&String.match?(&1, ~r/current-week/))
    |> Enum.sort
    |> List.last
  end

  def current_week(time) do # first week is week one
    doy = time.calendar.day_of_year(time.year, time.month, time.day)
    dow = time.calendar.day_of_week(time.year, time.month, time.day)
    week_num = div(doy + 6, 7)

    jan1 = get_local_time("2021-01-01")
    jan1_dow = time.calendar.day_of_week(jan1.year, jan1.month, jan1.day)

    if dow < jan1_dow, do: week_num + 1, else: week_num
  end

  def build_new_week_folder(week_num) do
    dir_name =
      if div(week_num, 10) > 0 do
        "current-week-#{week_num}"
      else
        "current-week-0#{week_num}"
      end

    add_new_dir(dir_name)
  end

  def add_new_dir(dir_name) do
    path = path(dir_name)
    if File.exists?(path), do: {:ok, path}, else: {File.mkdir(path), path}
  end

  def path(path, base \\ @target_from_loc)
  # must be sorted first -> last | base/first/last
  def path(path, base) when is_list(path) do
    Enum.reduce(path, base, fn part, link -> Path.join(link, part) end)
  end

  def path(path, base) when is_binary(path) do
    Path.join(base, path)
  end

  def template(file_name, datetime, todos \\ []) do
    date = format_date(datetime)
    tds = format_todos(todos)

    """
    # #{file_name}

    *#{date}*

    @ To complete:
    #{tds}
    ---

    """
  end

  def render_help_dialog do
    """
      NewLog | ./new_log ~ A daily markdown log file with carry-over todos.
      flags:
        -a add:              Adds a new file.
        -d date:    <string> "2021-01-01" - generate with specific date.
        -k keep:             Doesn't delete files from current week. I think.
        -n new:     <string> Creates new directory with name <string>.
        -s special: <string> Saves <file name> in 'special' dir.
        -h help:             Render this message.
        -z debug:            Access debug option.
    """
    |> IO.puts
  end
end
