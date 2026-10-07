# OC-TerminalConnector

A tiny command-line wrapper around [`openconnect`](https://www.infradead.org/openconnect/) that lets you connect to a VPN with a single word: `vpn`.

```console
$ vpn                         # connect (runs in the background)
VPN connected to vpn.example.com.

$ vpn status
VPN is running.

$ vpn change-server other.example.com
Server changed to other.example.com.

$ vpn off
VPN disconnected.
```

## Features

- **One command** to connect, disconnect, check status and switch servers
- **Runs in the background**, so your terminal stays free
- **Credentials stay out of the script**: they live in a private config file (`chmod 600`, enforced)
- **Works from any shell** (bash, zsh, fish, dash, ...) because the script carries its own `#!/usr/bin/env bash` shebang
- **Safe prompt handling**: passwords never appear in the process list or in temporary files, and special characters in passwords are supported
- **No retry loops**: if the login is rejected, it stops instead of hammering the server

## Requirements

Make sure these are installed **before** you install the project:

| Tool          | Purpose                                  |
| ------------- | ---------------------------------------- |
| `git`         | needed to download (clone) this repository |
| `openconnect` | the actual VPN client                    |
| `expect`      | answers openconnect's interactive prompts |
| `bash`        | runs the script                          |
| `sudo`        | openconnect needs root to create the tunnel |
| `setsid`      | part of `util-linux` (preinstalled on almost every distro); keeps the VPN alive after login |

`bash`, `sudo` and `setsid` come preinstalled on almost every Linux distribution. You usually only need to install `git`, `openconnect` and `expect`:

```bash
# Debian / Ubuntu
sudo apt install git openconnect expect

# Fedora / RHEL
sudo dnf install git openconnect expect

# Arch
sudo pacman -S git openconnect expect
```

Check that everything is installed:

```bash
git --version
openconnect --version
expect -v
```

## Installation

```bash
git clone https://github.com/Askmahan2006/OC-TerminalConnector.git
cd OC-TerminalConnector
./install.sh
```

Run `install.sh` as your **normal user** (not with `sudo`); it asks for sudo only when it needs to. It will:

1. check that the dependencies are installed,
2. copy `bin/vpn` to `/usr/local/bin/vpn`,
3. leave your login details for the first run of `vpn` (see below).

To install somewhere else (no sudo needed):

```bash
PREFIX="$HOME/.local" ./install.sh
```

### Manual installation

```bash
sudo install -m 755 bin/vpn /usr/local/bin/vpn
```

## First run and configuration

After `./install.sh`, the `vpn` command works from **any directory**, not only from the project folder.


The first time you run `vpn`, it asks for your details and saves them. No manual editing needed:

```console
$ vpn
No config found. Let's set up your VPN (first run only).
VPN server (hostname, e.g. vpn.example.com): vpn.example.com
Username: alice
Password:
Confirm password:
Saved to /home/alice/.config/vpn-cli/config
```

The details are stored in `~/.config/vpn-cli/config`, created with owner-only permissions (`600`). The password is typed hidden and any special characters are handled safely. `vpn` refuses to run if the file becomes readable by other users:

```bash
chmod 600 ~/.config/vpn-cli/config
```

If the password confirmation does not match, you get three more tries; after the last failed retry setup is cancelled and nothing is saved.

To change your login later, run `vpn setup` again, or edit the file by hand (see `config.example` for the format).

You can use a different config file (for example, a second VPN profile) with the `VPN_CONFIG` environment variable:

```bash
VPN_CONFIG=~/.config/vpn-cli/work vpn
```

## Usage

| Command                   | What it does                                            |
| ------------------------- | ------------------------------------------------------- |
| `vpn`                     | Connect (also: `vpn on`, `vpn connect`)                 |
| `vpn off`                 | Disconnect (also: `vpn disconnect`)                     |
| `vpn status`              | Show whether the VPN is running                         |
| `vpn setup`               | Enter or change your server, username and password      |
| `vpn change-server HOST`  | Check that `HOST` resolves, save it, and reconnect if currently connected |
| `vpn --help`              | Show help                                               |
| `vpn --version`           | Show the version                                        |

## How it works

`vpn` runs `expect` under `sudo`, so `sudo` asks for your password normally in your terminal (hidden, like any other sudo prompt). `expect` then starts `openconnect --background --no-dtls` and answers its prompts (certificate confirmation, username, password). Your VPN credentials are passed to `expect` through a pipe, so they never show up in `ps` output, in environment variables or in files on disk. Once connected, `openconnect` detaches into the background; `vpn off` stops it with `pkill -x openconnect`.

## Security notes

- Your password is stored **in plain text** in the config file. That is why the file must be `chmod 600`. For stronger setups, consider a password manager or a keyring and adapt `load_config` accordingly.
- The script automatically accepts the server's certificate prompt. If you want strict verification, pin the certificate with openconnect's `--servercert` option instead.
- **Never commit your real config file.** The included `.gitignore` helps, but double-check before pushing.

## Troubleshooting

| Problem                                   | Fix                                                        |
| ----------------------------------------- | ---------------------------------------------------------- |
| `'expect' is not installed`               | Install the dependencies (see above)                       |
| `vpn: command not found`                  | Run `./install.sh`, then open a new terminal (or `hash -r`). Check `echo $PATH` contains `/usr/local/bin` |
| `... is readable by other users`          | `chmod 600 ~/.config/vpn-cli/config`                       |
| `Login failed: wrong username or password?` | Run `vpn setup` to enter your details again              |
| `cannot resolve <host>`                   | Check the hostname and your DNS / internet connection      |
| `VPN is already running`                  | Run `vpn off`, then `vpn` again                            |
| Asks for the sudo password, then hangs    | Update to the latest version (`git pull && ./install.sh`)  |

## Uninstall

```bash
./install.sh --uninstall
```

Your config file is kept; delete `~/.config/vpn-cli/` yourself if you no longer need it.

## Contributing

Issues and pull requests are welcome. Please run [`shellcheck`](https://www.shellcheck.net/) on any script you change.

## Disclaimer

Use this tool only with VPN services you are authorized to use. It comes with no warranty.

## License

[MIT](LICENSE)
