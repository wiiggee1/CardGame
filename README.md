## Apples2Apples - CardGame 

This application, is part of the course D7032E. With the goal of refactoring java written code using best practices. 
For best practices, concepts such as `SOLID` principles, `Booch` metrics and design patterns are heavily focused on. 

#### General Information
- Code written in Zig. 
- Architecture... 
- ...

### Setup and how to run: 

1. Download the `zig` compiler on your machine, which can be found [here](https://ziglang.org/download/).
2. Running the program: 
    ```zsh
     zig build run -- --arg1 value1 --arg2=value2 ...
    ```

    e.g., 
    ```zsh
     zig build run -- --hosting true --num_players=2
    ```

    Running with the --help flag would yield the options: 

    ```zsh
    Usage: game setup [options]
      --help
      --hosting <y/n>
      --num_players <int>      Valid number is 1-8+
      --id <str>
      --ip
      --port
    ```
3. ...
