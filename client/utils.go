package main

import (
	"io/ioutil"
	"log"
	"os"
)

func disableLogging() {
	log.SetFlags(0)
	log.SetOutput(ioutil.Discard)
}

func validateEnv() {
	varNames := []string{"host", "port"}

	for _, varName := range varNames {
		if os.Getenv(varName) == "" {
			log.Fatalf("env variable '%s' is not set\n", varName)
		}
	}
}
