PREFIX      := $(HOME)/bin
PLIST_DIR   := $(HOME)/Library/LaunchAgents
PLIST_NAME  := com.isaozzz.monitorswitch.plist
LABEL       := com.isaozzz.monitorswitch

.PHONY: build install uninstall

build:
	swift build -c release

install: build
	@mkdir -p $(PREFIX)
	cp .build/arm64-apple-macosx/release/MonitorSwitch $(PREFIX)/
	@mkdir -p $(PLIST_DIR)
	@sed 's|__BIN__|$(PREFIX)/MonitorSwitch|' launchagent.plist > $(PLIST_DIR)/$(PLIST_NAME)
	@launchctl bootout gui/$$(id -u) $(PLIST_DIR)/$(PLIST_NAME) 2>/dev/null || true
	launchctl bootstrap gui/$$(id -u) $(PLIST_DIR)/$(PLIST_NAME)
	launchctl kickstart gui/$$(id -u)/$(LABEL)
	@echo "✔ installed and running"

uninstall:
	launchctl bootout gui/$$(id -u) $(PLIST_DIR)/$(PLIST_NAME) 2>/dev/null || true
	rm -f $(PREFIX)/MonitorSwitch
	rm -f $(PLIST_DIR)/$(PLIST_NAME)
	@echo "✔ uninstalled"
