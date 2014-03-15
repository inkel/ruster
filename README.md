# ruster - a simple Redis Cluster Administration tool

Control your [Redis][redis] [Cluster][redis-cluster] from the command
line.

## Usage

`ruster` relies on [redic][redic], the lightweight Redis client. It
currently allows to create a cluster, add and remove nodes, and
execute a command in all nodes in a cluster.

### Create a cluster

```
$ ruster create ip:port [ip:port...]
```

Creates a cluster with all the indicated nodes, and automatically
shards Redis Cluster 16,384 slots evenly among all of them.

### Add a node

```
$ ruster add cluster_ip:port ip:port
```

Adds `ip:port` to the cluster. `cluster_ip:port` must be one of the
nodes that are already part of the cluster.

### Remove a node

```
$ ruster remove cluster_ip:port ip:port
```

Removes `ip:port` from the cluster. `cluster_ip:port` must be one of the
nodes that are already part of the cluster. The only requirement is
that `ip:port` isn't the same as `cluster_ip:port`.

**NOTE**: removing a node that has slots assigned leaves the cluster
in a broken state. These slots should be resharded before removing the
node.

### Execute a command in all nodes

```
$ ruster call ip:port [CMD ...]
```

Executes the [Redis command][redis-commands] in all nodes, displaying
it's result in STDOUT.

### Reshard

```
$ ruster reshard cluster_ip:port slots target_ip:port source_ip:port [...]
```

Reshards the cluster at `cluster_ip:port`, by moving `slots` slots
from several `source_ip:port` to `target_ip:port`.

## TODO

* documentation
* resharding
* add interactive interface
* add REPL?
* fix cluster
* check cluster state
* cluster information
* ASSERTIONS

## Thanks

This work wouldn't have been possible without [@antirez][@antirez]
awesome work on Redis, and [@soveran][@soveran] and [@cyx][@cyx] for
their super lightweight Redis client.

Thank you to my dear friends [@lucasefe][@lucasefe], [@pote][@pote]
and [@elcuervo][@cuerbot], who joined the
[conversation on Twitter][nameme] while I was looking for a name.

Also, I'd like to thank to [Eruca Sativa][eruca] and [Cirse][cirse]
for the music that's currently blasting my speakers while I write
this.

[redis]: http://redis.io/
[redis-cluster]: http://redis.io/topics/cluster-tutorial
[redic]: https://github.com/amakawa/redic
[@antirez]: https://twitter.com/antirez
[@soveran]: https://twitter.com/soveran
[@cyx]: https://twitter.com/cyx
[eruca]: https://twitter.com/ErucaSativa
[cirse]: https://twitter.com/cirsemusic
[redis-commands]: http://redis.io/commands
[@cuerbot]: https://twitter.com/cuerbot
[@pote]: https://twitter.com/poteland
[@lucasefe]: https://twitter.com/lucasefe
[nameme]: https://twitter.com/inkel/status/444638064393326592
