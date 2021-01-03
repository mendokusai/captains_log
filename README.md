# NewLog

This is an escript tool for building daily developer logs in markdown.

The first version I made a few years ago was made in ruby using the `TTY` package which grossly simplified the file interface. Elixir has decent handling of `File` so I went and used it, The code is 2/3 longer, but I think it's better to debug ...eventually.


## Build

To make a build, use `mix escript.build` and then you can use it as an executable.

## Usage

```elixir
./new_log
```

Optional flags can be run using:

```elixir
./new_log --help
```


