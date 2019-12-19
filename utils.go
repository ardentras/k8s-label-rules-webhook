package main

import (
	"io/ioutil"
	"os"

	log "github.com/sirupsen/logrus"
)

func readFile(path string) []byte {
	data, fileErr := ioutil.ReadFile(path)
	if fileErr != nil {
		log.Fatal(fileErr)
	}
	return data
}

func str2bool(s string) bool {
	return s != ""
}

// Remove nil possibility
func errToStr(e error) string {
	if e != nil {
		return e.Error()
	}
	return ""
}

// Set default value for envirinment variable if not found
func getEnv(key, def string) string {
	val := os.Getenv(key)
	if len(val) == 0 {
		return def
	}
	return val
}
