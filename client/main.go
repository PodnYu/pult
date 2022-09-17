package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"os"
	"strings"

	"github.com/joho/godotenv"
	"github.com/pkg/errors"
)

type CommandHandler = func(net.Conn, string) error

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	validateEnv()

	if os.Getenv("log") != "on" {
		disableLogging()
	}

	host := os.Getenv("host")
	port := os.Getenv("port")

	start(host, port)
}

func start(host, port string) {
	log.Printf("connecting to %s:%s...\n", host, port)
	conn, err := connect(host, port)

	if err != nil {
		log.Fatal(err.Error())
	}
	defer conn.Close()

	log.Printf("connected\n")

	handlers := getCommandHandlers()

	handleConnection(conn, handlers)
}

func connect(host string, port string) (net.Conn, error) {
	address, err := net.ResolveTCPAddr("tcp", fmt.Sprintf("%s:%s", host, port))

	if err != nil {
		return nil, errors.Wrap(err, "Failed to resolve tcp address")
	}

	conn, err := net.DialTCP("tcp", nil, address)
	if err != nil {
		return nil, errors.Wrap(err, "Failed to dial")
	}

	return conn, err
}

func handleConnection(conn net.Conn, handlers map[string]CommandHandler) {
	reader := bufio.NewReader(conn)

	for {
		msg, err := reader.ReadString('\n')
		if err != nil {
			log.Printf("read failed: %s\n", err.Error())
			break
		}

		msg = strings.TrimSuffix(msg, "\n")

		log.Printf("got msg: '%s'\n", msg)

		splitted := strings.Split(msg, " ")
		cmd := splitted[0]
		args := strings.Join(splitted[1:], "")

		handler, ok := handlers[cmd]
		if !ok {
			log.Printf("unrecognized command: '%s'\n", cmd)
		}

		err = handler(conn, args)
		if err != nil {
			log.Printf("error occured: %s", err.Error())
		}
	}
}
