[![Pharo version](https://img.shields.io/badge/Pharo-14-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)

# MCP-Sonification

Hear what an agent does in your Pharo image. MCP-Sonification hooks into the observability of the [Pharo MCP server](https://github.com/Evref-BL/MCP) and turns every tool call into a [SoundBank](https://github.com/Gabriel-Darbord/SoundBank) event, with its context: a compile, a search, a test run that fails, the second failure in a row, a test that passes again, a call that is taking a while.

The observability data is untouched: the hook forwards everything to the MCP's own backend.

## Pharo Version Policy

This project is developed on Pharo 14, the only version it has been tested on.

## Installation

Load the project into a Pharo image with Metacello (it loads SoundBank and Scsynth too):

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'MCP-Sonification' commitish: 'main' path: 'src';
  baseline: 'MCPSonification';
  load
```

Playing sounds needs SuperCollider installed; see [Scsynth's installation](https://github.com/Gabriel-Darbord/Scsynth#installation).

## Quick Start

Start the sound engine with the bundled instruments bank, then attach it to the running MCP server:

```smalltalk
| engine bank mcp |
engine := SBEngine default.
bank := (IceRepository repositoryNamed: 'MCP-Sonification') location / 'banks' / 'instruments'.
engine start; loadBank: bank.
mcp := MCP allInstances anyOne. "the MCP server your agent talks to"
MCPSonificationBackend attachEngine: engine to: mcp.
```

Detach with `MCPSonificationBackend detachFrom: mcp`, and switch banks at any time with `engine loadBank:`.

## Events

Each tool call posts events whose subjects go from the tool's name, through any bank sets containing it, to its group, `read` or `write` (from the tool's read-only hint), and `*`:

| When | Phases, most important first |
|---|---|
| the call starts | `start` |
| it is still running after 2 s | `waiting` |
| it failed | `repeated-failure` (2nd failure in a row, any tool), `timeout`, `very-slow` (≥ 30 s), then `failure` (failing tests) or `error` |
| it succeeded | `recovered` (this tool failed last time), `very-slow`, `slow` (≥ 3 s), then `success` |

A bank therefore maps keys such as `method_compile.start`, `tests.recovered`, `write.success`, or `*.error`. Calls through `tool_call` are reported once, by the tool they run. Tune the thresholds with `mcp observability tracker`, for example `slowDuration: 5 seconds`.

## Banks

`banks/instruments` is a bank of synthesized instrument notes (pluck, marimba, bell, low tones) covering every MCP tool: a marimba melody for edits with a bell cadence on every 8th, bell arpeggios for tests, a low tritone for errors, and more. `tools/synthesize_instruments.py` regenerates its notes with the Python standard library.

To make your own bank, see [SoundBank's bank format](https://github.com/Gabriel-Darbord/SoundBank#banks) and use `banks/instruments/bank.ston` as a starting point.

## Documentation

The class comments of `MCPSonificationBackend` and `MCPSonificationTracker` describe the hook and the call context.
