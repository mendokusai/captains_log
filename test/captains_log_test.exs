defmodule CaptainsLog.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Prints the help dialog with the --help flag" do
    assert capture_io(fn ->
             CaptainsLog.main(["--help"])
           end) =~ "CaptainsLog | ./captains_log ~ A daily markdown log file with carry-over todos."
  end

  test "ensure_required_directories creates missing directories" do
    test_dir = System.tmp_dir!() |> Path.join("captains_log_test_#{:rand.uniform(10000)}")
    datetime = ~D[2025-06-28] |> DateTime.new!(~T[12:00:00])

    # Create the base directory first
    File.mkdir_p!(test_dir)

    assert {:ok, week_dir_name} = CaptainsLog.ensure_required_directories(test_dir, datetime)

    assert File.dir?(Path.join(test_dir, "history"))
    assert File.dir?(Path.join([test_dir, "history", "2025"]))
    assert File.dir?(Path.join(test_dir, week_dir_name))
    assert String.starts_with?(week_dir_name, "current-week-")

    on_exit(fn -> File.rm_rf!(test_dir) end)
  end

  test "current_week calculates correct week number" do
    # Test a date that should be week 2 (January 2025)
    datetime_week2 = ~D[2025-01-05] |> DateTime.new!(~T[12:00:00])
    assert CaptainsLog.current_week(datetime_week2) == 2

    # Test a date in late June (should be around week 26)
    datetime_june = ~D[2025-06-28] |> DateTime.new!(~T[12:00:00])
    week_num = CaptainsLog.current_week(datetime_june)
    assert week_num >= 25 and week_num <= 27
  end

  test "get_todos extracts todos from log content" do
    log_content = """
    # d01234.md
    @ To complete:
    @ - Fix the navigation bug
    @ - Add new tests
    ---
    Some content.
    @ - This should also be extracted
    """

    todos = CaptainsLog.get_todos(log_content)

    assert "Fix the navigation bug" in todos
    assert "Add new tests" in todos
    assert "This should also be extracted" in todos
    assert length(todos) == 3
  end

  test "get_week_number extracts number from week directory name" do
    assert CaptainsLog.get_week_number("current-week-05") == 5
    assert CaptainsLog.get_week_number("current-week-26") == 26
  end

  test "target_current_week finds current week directory" do
    directory_contents = [".DS_Store", "history", "current-week-26", "special"]
    assert CaptainsLog.target_current_week(directory_contents) == "current-week-26"

    # Multiple week directories - should return the last one
    directory_contents = ["current-week-25", "current-week-26", "history"]
    assert CaptainsLog.target_current_week(directory_contents) == "current-week-26"
  end
end
