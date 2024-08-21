package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/fatih/color"
)

var characters = map[string][]string{
	"default": {"(o_o)"},
	"cat":     {"(^._.^)"},
	"dog":     {"(ᵔᴥᵔ)"},
	"fumo_1":  {"ᗜˬᗜ", "ᗜ˰ᗜ"},
	"fumo_2":  {"ᗜ ̫ ᗜ"},
	"fumo_3":  {"ᗜ‿ᗜ"},
	"x":       {"X‿X", "-‿X", "X‿-"},
	"zero":    {"0x0", "-x-", "0x0"},
}

const outputLines = 10 // Number of output lines to display

func main() {
	message := flag.String("message", "Hello, I'm lil guy!", "Message to display")
	characterName := flag.String("character", "default", "Character to use (default, cat, dog, fumo_1, fumo_2, fumo_3, x, zero)")
	flag.Parse()

	character, ok := characters[*characterName]
	if !ok {
		character = characters["default"]
	}

	frames := []string{"<", "-", ">", " "}

	// Clear screen and hide cursor
	fmt.Print("\033[2J\033[H\033[?25l")
	defer fmt.Print("\033[?25h") // Show cursor when done

	c := color.New(color.FgCyan)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	outputChan := make(chan string)
	go readStdin(outputChan)

	go func() {
		<-sigChan
		fmt.Print("\033[?25h") // Show cursor before exiting
		os.Exit(0)
	}()

	characterIndex := 0
	outputBuffer := make([]string, outputLines)
	for i := range outputBuffer {
		outputBuffer[i] = "" // Initialize with empty strings
	}

	for {
		for _, frame := range frames {
			// Move cursor to top-left and print animation
			fmt.Print("\033[H")

			leftArm, rightArm := getArms(frame)

			c.Printf("  %s %s %s\n\n", leftArm, character[characterIndex], rightArm)
			fmt.Printf("  %s\n\n", *message)

			// Display the last few lines of output
			for _, line := range outputBuffer {
				if line != "" {
					fmt.Printf("  %s\n", line)
				}
			}

			// Add padding to cover any previous longer messages
			padding := strings.Repeat(" ", 50)
			fmt.Printf("%s\n", padding)

			time.Sleep(250 * time.Millisecond)

			// Check for new output
			select {
			case newOutput := <-outputChan:
				// Shift the buffer and add the new output
				outputBuffer = append(outputBuffer[1:], newOutput)
			default:
				// No new output, continue with the current buffer
			}
		}

		// Cycle to the next face for the character
		characterIndex = (characterIndex + 1) % len(character)
	}
}

func readStdin(outputChan chan<- string) {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		outputChan <- scanner.Text()
	}
}

func getArms(frame string) (string, string) {
	switch frame {
	case "<":
		return "<", "<"
	case ">":
		return ">", ">"
	default:
		return frame, frame
	}
}
