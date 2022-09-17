# Pult client

#### [Pult server](../server/README.md)

This is a 'follower' client. It should be running on the **controlled** system. Currently it understands only one command - `make_screenshot` and is implemented for Windows only.

The clients uses WinAPI to actually make a screenshot. It is written using Golang programming language because it is compiled to executables and it's relatively easy to work with WinAPI here.

## Run

The client is configured via .env file.

Copy .example.env to .env and replace the values according to your needs:

```
cp .example.env .env
```

Run the client:

```
go run .
```
