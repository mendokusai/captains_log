defmodule NewLog.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Prints the help dialog with the --help flag" do
    assert capture_io(fn ->
             NewLog.main(["--help"])
           end) =~ "NewLog | ./new_log ~ A daily markdown log file with carry-over todos."

    refute File.exists?("priv/current-week-02/d01235.md") == true
  end

  test "in the same week, adds new log" do
    date = "2021-01-07"
    NewLog.main(["--date", date])

    file_path = "priv/current-week-02/d01235.md"
    assert File.exists?(file_path) == true

    on_exit(fn ->
      File.rm!(file_path)
    end)
  end

  test "in a new week creates a new 'current week' folder & archives previous" do
    NewLog.main(["--date", "2021-01-13"])

    assert File.exists?("priv/history/2021/week 02/d01234.md") == true
    assert File.exists?("priv/current-week-03/d01235.md") == true

    on_exit(fn ->
      newest_path = "priv/current-week-03"
      old_path = "priv/current-week-02"
      archive_path = "priv/history/2021/week 02"
      File.rm_rf!(newest_path)
      File.mkdir!(old_path)
      File.cp_r(archive_path, old_path)
      File.rm_rf!(archive_path)
    end)
  end

  test "priv path navigation" do
    assert NewLog.navigate_to_path("priv") == {:ok, ["history", "current-week-02"]}

    on_exit(fn ->
      NewLog.navigate_to_path("Code/elixir/new_log")
    end)
  end

  test "local navigation" do
    assert NewLog.navigate_to_path("Sb/dev_log") ==
             {:ok, [".DS_Store", "test", "special", "history", "current-week-02"]}

    on_exit(fn ->
      NewLog.navigate_to_path("Code/elixir/new_log")
    end)
  end

  test "Destop location" do
    File.cd("../../../Desktop")

    assert NewLog.navigate_to_path("Sb/dev_log") ==
             {:ok, [".DS_Store", "test", "special", "history", "current-week-02"]}

    on_exit(fn ->
      NewLog.navigate_to_path("Code/elixir/new_log")
    end)
  end
end
