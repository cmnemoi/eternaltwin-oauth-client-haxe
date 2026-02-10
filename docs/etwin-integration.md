[Home](../index.md) | [Applications](./index.md)

# Eternaltwin Integration

This section describes how to integrate Eternaltwin into your project's
repository. Integrating Eternaltwin to your repository allows you to run and
test your project using a locally installed version of the Eternaltwin website.

Eternaltwin is installed as a project-local Node package:
- it ensures all the contributors use the same version
- the project is fully self-contained and does not require an internet
  connection to run
- if you have multiple projects on your computer, there are no conflicts: each
  one has its own Eternaltwin version.

The packaged version is not the full website (for example, it does not include
translations). It's a lightweight version specifically intended to be installed
inside other projects.

## System requirements

You need the following tools on your system:
- [Node.js](../tools/node.md): Version `18.17.0` or higher
- [Yarn](../tools/yarn.md)

If your system is not a 64-bit Linux or Windows, you also need [Rust](https://rustup.rs/) to
complete the installation by compiling part of the package. If you have a 64-bit Linux or Windows,
Rust is optional.

**ℹ** Using **npm** as an alternative to **yarn** is not officially supported but should work.

## Configure your repository for Node packages

Your repository must contain a `package.json` file at its root. It is a
manifest file containing metadata for Node.js.

If your project does not have a `package.json`, you may create one by running
the following command at the repo root and replying to the prompts:

```
yarn init .
```

You may read the [Yarn](https://yarnpkg.com/configuration/manifest) or
[npm](https://docs.npmjs.com/cli/v6/configuring-npm/package-json) documentation
if you wish to learn more about `package.json` files.

Below is an example minimal `package.json` file.

```json
{
  "name": "myproject",
  "version": "0.0.1",
  "licenses": [
    {
      "type": "AGPL-3.0-or-later",
      "url": "https://spdx.org/licenses/AGPL-3.0-or-later.html"
    }
  ],
  "private": true,
  "scripts": {},
  "dependencies": {},
  "devDependencies": {}
}
```

Make sure to commit the `package.json` file.

## Install Eternaltwin inside your project

Run the following command in the directory containing `package.json`:

```
yarn add --dev @eternaltwin/cli
```

This will perform the following 3 actions:
1. Update your `package.json` file to document the new dependency on the package `@eternaltwin/cli`.
2. Download the package (and its own dependencies) into the `node_modules` directory.
3. Create (or update) a `yarn.lock` file to remember the exact version of the dependencies that
   were installed and prevent accidental regressions.

Commit the `package.json` and `yarn.lock` files.

Do not commit the `node_modules` directory: add the `node_modules/` rule to your `.gitignore` file.

You now have to update your `package.json` file to expose the `eternaltwin` command.
Add the entry `"eternaltwin": "eternaltwin"` to the `scripts` config in your `package.json`.
The resulting `package.json` should be similar to:

```json
{
  "name": "myproject",
  "version": "0.0.1",
  "licenses": [
    {
      "type": "AGPL-3.0-or-later",
      "url": "https://spdx.org/licenses/AGPL-3.0-or-later.html"
    }
  ],
  "private": true,
  "scripts": {
    "eternaltwin": "eternaltwin"
  },
  "dependencies": {},
  "devDependencies": {
    "@eternaltwin/cli": "^0.16.0"
  }
}
```

**⚠ The package was previously named `@eternal-twin/website` or `@eternal-twin/cli`, it was renamed to `@eternaltwin/cli`.**
Make sure you use the right package.

## Start Eternaltwin

Once Eternaltwin is installed, you can run it from anywhere
inside your repo using the following command:

```
yarn eternaltwin start
```

This command starts the local Eternaltwin server on your computer. You can
use this server to test your project.

When starting, the server displays the configuration it is using. You can use
this information to troubleshoot your configuration.

By default, the server uses the port `50320` and is available at the address
<http://localhost:50320/>.

## Configure Eternaltwin

You can configure Eternaltwin to your personal preferences (the most notable is being able to run it with a Postgres database so you can have a persistent environment).

The Eternaltwin configuration is loaded from a file named `eternaltwin.local.toml`.

This file may contain configuration specific to your local machine and as such
should not be stored in Git. The recommended strategy to configure Eternaltwin
is the following:

1. Create a file named `eternaltwin.local.toml`.
2. Copy [the official example configuration](https://gitlab.com/eternaltwin/eternaltwin/-/blob/master/eternaltwin.toml)
   ([raw](https://gitlab.com/eternaltwin/eternaltwin/-/raw/master/eternaltwin.toml))
   into `eternaltwin.toml`. You do not need to customize the config yet.
3. Add the `eternaltwin.local.toml` rule to your `.gitignore`, commit the file `eternaltwin.toml`
4. Update your project setup documentation: contributors should copy the file `eternaltwin.toml`
   into `eternaltwin.local.toml` manually.
5. Copy your `eternaltwin.toml` file into `eternaltwin.local.toml`.

## Other commands

`yarn eternaltwin` provides a couple subcommands:

- `yarn eternaltwin start`: Start the dev version of the website
- `yarn eternaltwin db check`: Check the state of the Postgres database used by the dev website if configured to use the `postgres` mode
- `yarn eternaltwin db reset`: Initialize an empty database
- `yarn eternaltwin db sync`: Upgrade an existing database to the latest schema version

## Next steps

Now that your repo is configured to run Eternaltwin, you may start to actually
integrate your project with Eternaltwin. The first step would be to [use
Eternaltwin to manage user accounts through OAuth](./etwin-oauth.md).
