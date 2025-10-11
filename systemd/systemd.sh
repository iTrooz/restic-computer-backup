SYSTEMD_USER_DIR=$(HOME)/.config/systemd/user

.PHONY: install
install:
	mkdir -p $(SYSTEMD_USER_DIR)
	install -m 644 restic.service $(SYSTEMD_USER_DIR)/
	install -m 644 restic.timer $(SYSTEMD_USER_DIR)/
	systemctl --user daemon-reload
	systemctl --user enable --now restic.timer

.PHONY: uninstall
uninstall:
	systemctl --user disable --now restic.timer
	rm -f $(SYSTEMD_USER_DIR)/restic.service
	rm -f $(SYSTEMD_USER_DIR)/restic.timer
	systemctl --user daemon-reload
