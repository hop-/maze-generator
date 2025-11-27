# Maze Generator

A fast and efficient maze generator written in Zig, featuring configurable generation algorithms and customizable maze properties.

## Features

- **Multiple Generation Algorithms**: Currently supports Growing Tree algorithm
- **Configurable Parameters**: Control maze dimensions, randomness (seed), and difficulty
- **File Output**: Export generated mazes to text files
- **Command Line Interface**: Easy-to-use CLI with Unix-style command-like options

## Installation

### Prerequisites

- [Zig](https://ziglang.org/download/) (version 0.15.2 or later)

### Building from Source

```bash
git clone https://github.com/hop-/maze-generator.git
cd maze-generator
zig build
```

The compiled binary will be available at `zig-out/bin/maze_generator`.

## Usage

### Basic Usage

Generate a default 20x20 maze:

```bash
maze_generator
```

### Command Line

Use `--help` or `-h` to see all available options

```bash
maze_generator --help
```

### Examples

Generate a 50x30 maze with specific seed:

```bash
maze_generator --width 50 --height 30 --seed 12345
```

Create a more complex maze with higher hardness:

```bash
maze_generator -W 100 -H 100 --hardness 255 --output complex_maze.txt
```

Generate a simple maze with lower hardness:

```bash
maze_generator --level 50 --output simple_maze.txt
```

## Algorithm

The maze generator uses a modular architecture to support multiple maze generation algorithms.

### Growing Tree Algorithm

The maze generator implements the **Growing Tree** algorithm, which creates mazes with interesting branching patterns and configurable complexity through the hardness parameter.

### Patch-Based Generation (Based on Growing Tree Algorithm)

The maze is divided into patches, and the Growing Tree algorithm is applied to each patch independently. This approach allows for better control over maze complexity structure and parrallel generation.

### Hardness Parameter

The hardness parameter (0-255) controls the complexity and branching behavior of the generated maze:

- **Low values (0-50)**: More linear paths, simpler maze structure
- **Medium values (50-150)**: Balanced complexity with moderate branching
- **High values (150-255)**: More complex mazes with extensive branching

## Project Structure

```none
maze-generator/
├── src/
│   ├── main.zig              # Main entry point and CLI handling
│   ├── options.zig           # Command line argument parsing
│   ├── utils.zig             # Utility functions
│   ├── writer.zig            # File output functionality
│   ├── core/                 # Core maze data structures and logic
│   │   ├── cell.zig          # Cell data structure
│   │   ├── coordinates.zig   # Coordinate system
│   │   ├── direction.zig     # Direction handling
│   │   └── maze.zig          # Main maze data structure
│   └── generator/
│       ├── types.zig         # Generation configuration
│       ├── generator.zig     # Generator interface
│       └── ...               # Generation algorithms
├── build.zig                 # Zig build configuration
├── build.zig.zon             # Zig build manifest
└── README.md                 # This file
```

## Output Format

The generated maze is saved as a text file using ASCII characters:

- `[]` represents walls
- `  ` (space) represents open paths
- `>M` represents the maze entrance
- `M>` represents the maze exit

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Future Features

- Additional generation algorithms
- Multiple output formats (PNG, SVG, JSON)

## Author

Created by [hop-](https://github.com/hop-)
