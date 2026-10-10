DIR ?= ./test_folder
MALICIOUS_DIR ?= ./quarantine_folder
INTERVAL ?= 5

.PHONY: all setup run restore clean

all: setup run

setup:
	@mkdir -p $(DIR)
	@mkdir -p $(MALICIOUS_DIR)
	@echo "Setup complete."

run: setup
	@echo "Starting Antivirus Daemon monitoring '$(DIR)' every $(INTERVAL) seconds..."
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

restore: setup
	@echo "starting restore Utility..."
	./restore.sh $(DIR) $(MALICIOUS_DIR)

clean:
	@rm -f directory-info.last directory-info.new .whitelist
	@echo "Cleaned runtime files."