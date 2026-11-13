# orchard-tools

Collection of tools for [Orchard](https://github.com/aerth/orchard).

Some, such as [web_search](./toolboxes/web/web_search.bash) and [scrape_website](./toolboxes/web/scrape_website.bash), require environmental variables to be placed in a .env file.

Others might require programs to be installed, such as `sqlite` or `bat`.

## install and use

First, get orchard interface, such as [orchard-tui](https://github.com/aerth/orchard-tui).

Set the ORCHARD_TOOLS environmental variable to the path where your tools live.

Create a `${ORCHARD_TOOLS}/.env` file that contains BRAVE_API_KEY.
Otherwise you will want to move that tool to ./disabled/

Run orchard-tui using this toolbox, using a database for persistence:

```bash
git clone https://github.com/aerth/orchard-tools ~/src/otools
ORCHARD_TOOLS=~/src/otools orchard-tui -db /tmp/chat.db --bash
```

Prompt: _"Read /tmp/chat.db and tell me what was the first message in the database?"_

The agent should start calling the [sqlite_select](./toolboxes/sqlite_select.bash) tool..

```json
{"id":"call_dazemwoy","index":0,"type":"function","function":{"name":"sqlite_select","arguments":"{\"db_path\":\"/tmp/chat.db\",\"query\":\"PRAGMA table_info(chat_messages);\"}"}}
```

```json
{"id":"call_mj50318r","index":0,"type":"function","function":{"name":"sqlite_select","arguments":"{\"db_path\":\"/tmp/chat.db\",\"query\":\"SELECT content FROM chat_messages ORDER BY created_at ASC LIMIT 1;\"}"}}

```

Bot: _The first message in the database was: "Read /tmp/chat.db and tell me what was the first message in the database?"_

(true!)

## adding tools

Add a new bash script in a named toolbox directory. The filename (minus file extension) will be the name of the tool given to the LLM. The description and parameters come from the first lines of the script. See examples: [./toolboxes/](./toolboxes/)

Notice the commented lines are at the top of each script.
These are parsed at startup, for toolcall args (object/map) to be parsed as positional arguments:

```bash
#!/usr/bin/env bash
# Description: Execute an SQL query on a SQLite database and return formatted results.
# Param: db_path - Path to the SQLite database file [string] [required]
# Param: query - The SQL query to execute [string] [required]
```

## python tools

Some tools you might want to implement in python for whatever reason.
The python scripts must have the spec comment lines like the bash scripts.

After cloning this repo, enter the dir and initialize a virtual env at .venv

```bash
uv venv
```

You may use python3 venv instead:

```bash
python -m venv .venv
```

## Subject to change

[This toolbox repository](https://github.com/aerth/orchard-tools) might change, and tool scripts might be added or removed.
Clone and write tool scripts to make your own stable toolbox, with tools for your specific workflows.
