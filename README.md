# orchard-tools

Collection of tools for [Orchard](https://github.com/aerth/orchard).

## install and use

First, get orchard interface, such as [orchard-tui](https://github.com/aerth/orchard-tui).

Set the ORCHARD_TOOLS environmental variable to the path where your tools live.

```bash
git clone https://github.com/aerth/orchard-tools ~/src/otools
ORCHARD_TOOLS=~/src/otools orchard-tui -db /tmp/chat.db
```


Prompt: _"Read /tmp/chat.db and tell me what was the first message in the database?"_

The agent should start calling the [sqlite_select](./toolboxes/sqlite_select.bash) tool..
```json
{"id":"call_dazemwoy","index":0,"type":"function","function":{"name":"sqlite_select","arguments":"{\"db_path\":\"/tmp/chat.db\",\"query\":\"PRAGMA table_info(chat_messages);\"}"}}
...
{"id":"call_mj50318r","index":0,"type":"function","function":{"name":"sqlite_select","arguments":"{\"db_pa
th\":\"/tmp/chat.db\",\"query\":\"SELECT content FROM chat_messages ORDER BY created_at ASC LIMIT 1;\"}"}}

```

Bot: _The first message in the database was: "Read /tmp/chat.db and tell me what was the first message in the database?"_

(true!)

## adding tools

Add a new bash script. The filename (minus file extension) will be the name of the tool given to the LLM. The description and parameters come from the first lines of the script. See examples: [./toolboxes/](./toolboxes/)

## python tools

Some tools you might want to implement in python for whatever reason.
After cloning this repo, enter the dir and initialize a virtual env at .venv

  uv venv

You may use python3 venv instead:

  python -m venv .venv

## Subject to change

This repository might change, such as adding or removing tool scripts.
