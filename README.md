# Abaco CLI

[![DOI](https://zenodo.org/badge/116715118.svg)](https://zenodo.org/badge/latestdoi/116715118)

Command line interface for working with the Abaco (Actor Based Containers) API

Dependent upon [jq](https://stedolan.github.io/jq/), getopts, and the [Agave CLI](https://bitbucket.org/agaveapi/cli)

## Installation and set up

Clone the repo, enable bash completion, and add the contents of the cloned repo to your path. Then, pull and cache a valid SD2E access token using the Agave CLI.
```
$ git clone https://github.com/TACC-Cloud/abaco-cli.git
$ source abaco-cli/abaco-completion.sh
$ $ export PATH=$PATH:$PWD/abaco-cli/
$ auth-tokens-create -S
```

## Usage

There are eleven possible commands. They can be seen using the tab completion set up above; simply set up the `abaco` command and hit the tab key twice.
```
$ abaco 
create    deploy       init    logs           submit    workers
delete    executions   list    permissions    update
```

Each command has a help message, which can be viewed with the `-h` flag. The `abaco` command also has a help message that overviews the function of each command, as shown below.
```
$ abaco -h

Usage: abaco [COMMAND] [OPTION]...

Set of commands for interacting with Abaco API. Options vary by 
command; use -h flag after command to view usage details.

Commands:
  list, ls, actors, images    list actors
  create, make, register      create new actor
  delete, remove, rm          remove actor
  update, change              update base Docker image
  permissions, share          list and update actor permissions
  workers, worker             view and add workers
  submit, run                 run actor
  executions                  view actor executions
  logs                        view execution logs
  init                        create a new actor project
  deploy                      build and deploy an actor
```

## Tutorial

Here, we'll outline nine commands in the Abaco workflow, skipping `abaco init` and `abaco deploy` for now. We use a [sample Docker container](https://hub.docker.com/r/jturcino/abaco-trial/) called `jturcino/abaco-trial`. When run, it prints the actor's environmental and context variables generated via [agavepy](https://github.com/TACC/agavepy), as well as printing the message passed by the user and the files present at the root of the container's filesystem.

1. **Create the actor** with `abaco create` using a Docker container. The command outputs the actor's name and ID. To customize our actor's environment, we will also pass two default environment variables using the `-e` flag.
```
$ abaco create -n tutorial-example -e foo=bar -e bar=baz jturcino/abaco-trial:latest
tutorial-example  JmlG71b4rxOrv
```

2. **Check actor's status** with `abaco list`. The commad outputs all actor names, IDs, and statuses. To view a detailed JSON description, use the `-v` flag and append the actor ID to the end of the command.
```
$ abaco list
tutorial-example    JmlG71b4rxOrv    READY
```

3. **Run the actor** with `abaco submit` once the status is `READY`. Pass information to the actor with the `-m` flag as a string or as JSON (here using JSON); this information will be available as a dictionary under `message_dict` in the actor's Agavepy context. Be sure to append the actor ID to the end of the command. `abaco submit` outputs the execution ID and `MSG` input.
```
$ msg='{"key1":"value1", "key2":"value2"}'
$ abaco submit -m "$msg" JmlG71b4rxOrv
WxeyJbqxQbK6W
{
  "key1": "value1",
  "key2": "value2"
}
```

4. **Check job status** with `abaco executions`. Providing only the actor ID lists all execution IDs associated with that actor. Providing the execution ID (output from `abaco-submit`) after the actor ID returns the job's status and worker ID.
```
$ abaco executions JmlG71b4rxOrv WxeyJbqxQbK6W
VlejLeLxVNWQv    COMPLETE
```

5. **(Optional) View worker description** with `abaco workers`. Output is a list of associated worker IDs and their statuses. A longer JSON description is returned if a worker ID is provided with the `-w` flag.
```
$ abaco workers JmlG71b4rxOrv
VlejLeLxVNWQv    READY
```

6. **Examine job log** with `abaco logs` by providing both the actor ID and execution ID. For our sample container, we can see the full agavepy context, the JSON message we passed to the actor, and the full environment. Notice how the environmental variables we passed in the `abaco-create` step (`foo=bar` and `bar=baz`) are readily available in the environment.
```
$ abaco logs JmlG71b4rxOrv WxeyJbqxQbK6W
Logs for execution WxeyJbqxQbK6W:
FULL CONTEXT:
{
  "username": "jturcino", 
  "HOSTNAME": "d10bb601307c", 
  "_abaco_actor_id": "JmlG71b4rxOrv", 
  "raw_message": "{'key2': 'value2', 'key1': 'value1'}", 
  "actor_dbid": "SD2E_JmlG71b4rxOrv", 
  "_abaco_actor_state": "{}", 
  "content_type": null, 
  "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 
  "MSG": "{'key2': 'value2', 'key1': 'value1'}", 
  "bar": "baz", 
  "_abaco_api_server": "https://api.sd2e.org", 
  "_abaco_Content_Type": "application/json", 
  "execution_id": "WxeyJbqxQbK6W", 
  "_abaco_access_token": "XXXXXXXXXXXXXXXXXXXXXXXXXX", 
  "message_dict": {
    "key2": "value2", 
    "key1": "value1"
  }, 
  "_abaco_actor_dbid": "SD2E_JmlG71b4rxOrv", 
  "_abaco_jwt_header_name": "X-Jwt-Assertion-Sd2E", 
  "_abaco_execution_id": "WxeyJbqxQbK6W", 
  "state": "{}", 
  "_abaco_username": "jturcino", 
  "actor_id": "JmlG71b4rxOrv", 
  "foo": "bar", 
  "HOME": "/"
}

MESSAGE:
{
  "key2": "value2", 
  "key1": "value1"
}

FULL ENVIRONMENT:
{
  "_abaco_actor_state": "{}", 
  "foo": "bar", 
  "bar": "baz", 
  "_abaco_actor_dbid": "SD2E_JmlG71b4rxOrv", 
  "_abaco_jwt_header_name": "X-Jwt-Assertion-Sd2E", 
  "_abaco_execution_id": "WxeyJbqxQbK6W", 
  "_abaco_username": "jturcino", 
  "HOSTNAME": "d10bb601307c", 
  "_abaco_actor_id": "JmlG71b4rxOrv", 
  "_abaco_access_token": "XXXXXXXXXXXXXXXXXXXXXXXXXX", 
  "MSG": "{'key2': 'value2', 'key1': 'value1'}", 
  "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 
  "_abaco_api_server": "https://api.sd2e.org", 
  "HOME": "/", 
  "_abaco_Content_Type": "application/json"
}

ROOT FILES:
bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv 
sys tmp usr var agavepy script.py requirements.txt .dockerenv work 
corral corral-repl
```

7. **Share the actor** with `abaco logs` to allow another member of your team access to your actor now that we know the actor is up and running properly. There are four permission levels: `NONE`, `READ`, `EXECUTE`, and `UPDATE`.
```
$ abaco permissions -u jfonner -p EXECUTE JmlG71b4rxOrv
jfonner     EXECUTE
jturcino    UPDATE
```

8. **Update the actor** with `abaco update` to use a new Docker container. Say we have updated `jturcino/abaco-trial` to have a new tag, `latest`, that we now want our actor to use. 
```
$ abaco update JmlG71b4rxOrv jturcino/abaco-trial:update
tutorial-example  JmlG71b4rxOrv  jturcino/abaco-trial:update
```
The actor is now using the `update` tag, rather than the `latest` tag. We can see this by submitting a new job and viewing it's logs (shown partially below). There should be a new message at the end of the log file!
```
$ abaco submit -m 'new message' JmlG71b4rxOrv
JKy13NYjY6amy
'new message'
$ abaco logs JmlG71b4rxOrv JKy13NYjY6amy
Logs for execution JKy13NYjY6amy:
...
THIS IS AN ACTOR UPDATE MESSAGE
```

9. **Delete the actor** with `abaco delete` by providing the actor ID.
```
$ abaco delete JmlG71b4rxOrv
Actor deleted successfully.
```
