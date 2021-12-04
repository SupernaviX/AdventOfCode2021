# Advent of Code 2021

## About

[Advent of Code](https://adventofcode.com) is an annual programming puzzle challenge organized by [Eric Wastl](https://was.tl/). From December 1 to December 25, a new puzzle is uploaded every day.

I'm following a self-imposed challenge to run this year's challenge using my own bootstrapped Forth interpreter. It's still a work in progress, but using it for "real" problems helps to flesh out bugs.

## Running the code

The Forth interpreter lives at https://github.com/SupernaviX/forsm.

`wasmer path/to/forsm.wasm --mapdir=.:path/to/forsm --mapdir=aoc:. aoc/01/part1.fth`