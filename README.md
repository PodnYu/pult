# Pult

### Pult - client-server app to 'control' another machine.

It consists of three parts - server, leader client, follower client:

- _Server_ - a TCP server, which purpose is to be a communication channel between clients (p2p?).
- _Leader client_ - **controlling client**. It connects to the server, choses one of the **follower clients**, sends commands to it via server and receives responses.
- _follower client_ - **client under control** - connects to the server, receives commands from **leader client**, and sends responses.

[Server](./server/README.md)

[Follower client](./client/README.md)

## Functionality

Currently there is only a screenshot functionality implemented: leader sends `make_screenshot` command, follower takes a screenshot and sends it to the leader in png format.
