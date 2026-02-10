# Eternaltwin configuration

This document describes Eternaltwin's configuration, it's based on the [general
config guidelines](./config.md).

## Reference

See `eternaltwin.toml` in main repository.

## Algorithm

### Init

The very first step is the config initialization: deciding which config sources
to use.

TODO: Log format, verbosity

1. Process the lines marked as **(env)** if `env_config` is true. Default is `true`,
   can be set explicitly with `--env-config` or `--no-env-config`.
2. Find the Eternaltwin profile.
   1. `--profile` CLI argument
   2. **(env)** If missing, `ETERNALTWIN_PROFILE` env var
   3. If missing, `dev`
3. If `env_config` was not set explicitly through the CLI, and the profile was
   not set through an env var and the profile is `sdk`, set `env_config` to
   false.
4. Pick the configuration sources
   1. Split arguments in contiguous groups:
      1. `--config`, `--config-format` (exact source location)
      2. `--config-data`, `--config-data-format` (inline config)
      3. `--config-search`, `--config-search-format`
   2. **(env)** If none of the above CLI args are present, use the environment
      variable `ETERNALFEST_CONFIG` if present. First try to interpret it as
      a JSON array of sources, otherwise intepret it as a URL (exact source
      location).
   3. Otherwise, default to a config search for
      `./eternaltwin.{profile}.local.toml`, `./eternaltwin.{profile}.local.json`,
      `./eternaltwin.{profile}.toml`, `./eternaltwin.{profile}.json`,
      `./eternaltwin.local.toml`, `./eternaltwin.local.json`,
      `./eternaltwin.toml`, `./eternaltwin.json`; where `profile` is the value
      of `profile`.

### Config resolution

1. Config sources are ordered with the first one having the lowest priority and
   the last one having the highest priority.
2. A default config from the code is inserted at the very beginning. There are
   four builtin default configs: `prod`, `dev`, `test` and `sdk`. If the profile
   matches a builting config, use it. Other profiles are custom profiles, they
   start with `dev`.
3. Starting from the end, find the content of the config source. For exact
   locations, read the location. For inline config, read the data. For search,
   search starting from the current working directory and going through parents.
   Stop at the first found.
   For each config, check the `extends` field. It's either a source, or an array
   of sources. Push it on the stack.
   If a config location is present multiple time, skip it the second time.
4. You now have a fully resolved list of configs. Each config remembers its
   location and content.


### Config resolution

The config is resolved by starting with a default config embedded in the
Eternaltwin code, and then iteratively updating it by merging values from the
sources found in the **Init** step.

1. (lowest priority)
2. If there are explicit sources, load them.

## Design

### Should default config search look into subdirectories? (e.g. `.config/eternaltwin.toml)

There was a [Node issue](https://github.com/nodejs/tooling/issues/79) about
the proliferation of config files at the repo root, with the proposition to
use `.config/` as an alternative. The issue with using a subdirectory is that
scoping is no longer obvious. Because of this, Eternaltwin only does regular
lookups.

### Should config search support globs?

Globs make ordering more ambiguous, especially if allowing to traverse
directories. Since Eternaltwin uses ordering for config merges, globs are not
supported.

### Implicit or explicit extend

Search stops at the first result instead of searching all matches. Combining
configs requires an explicit `extends`. This is similar to TypeScript or Eslint.

#### Argfile support

If a CLI arg is prefixed with `@`, javac treats it as an argfile and expands it
in place. See [Javac documentation](https://docs.oracle.com/javase/7/docs/technotes/tools/windows/javac.html#commandlineargfile).
We don't support it, but it's a neat idea.
