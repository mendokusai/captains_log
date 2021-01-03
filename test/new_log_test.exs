defmodule NewLog.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Prints the help dialog with the --help flag" do
    assert capture_io(fn ->
      NewLog.main(["--help"])
    end) =~  "NewLog | ./new_log ~ A daily markdown log file with carry-over todos."
  end

  test "in the same week, adds new log" do
    date = "2021-01-07"
    NewLog.main(["--date", date])

    file_path = "priv/current-week-01/d01235.md"

    assert File.exists?(file_path) == true
    File.rm!(file_path)
  end

  test "in a new week creates a new 'current week' folder" do
    date = "2021-01-18"
    NewLog.main(["--date", date, "--keep"])

    file_path = "priv/current-week-02/d01235.md"

    assert File.exists?(file_path) == true
    File.rm!(file_path)
  end
end
