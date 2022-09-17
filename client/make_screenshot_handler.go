package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image"
	"image/png"
	"log"
	"net"

	"github.com/PodnYu/remote-screenshot/screenshot"
)

func makeScreenshot(conn net.Conn, args string) error {
	img, err := screenshot.CaptureScreen()
	if err != nil {
		return err
	}

	receiverId := args

	_, err = conn.Write([]byte(fmt.Sprintf("screenshot %s\n", receiverId)))
	if err != nil {
		return err
	}

	return sendImage(conn, img)
}

func sendImage(conn net.Conn, img image.Image) error {
	buf := new(bytes.Buffer)
	png.Encode(buf, img)

	size := buf.Len()
	log.Printf("img size: %d\n", size)

	if err := sendImageSize(conn, size); err != nil {
		return err
	}

	_, err := conn.Write(buf.Bytes())

	return err
}

func sendImageSize(conn net.Conn, size int) error {
	sizeBuf := make([]byte, 4)
	binary.LittleEndian.PutUint32(sizeBuf, uint32(size))
	_, err := conn.Write(sizeBuf)

	return err
}
