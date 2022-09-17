package main

func getCommandHandlers() map[string]CommandHandler {
	return map[string]CommandHandler{"make_screenshot": makeScreenshot}
}
