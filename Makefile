# oocut v0.2.0 Makefile

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oocut

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.2.0)

.PHONY: build check line-cap file-law academy density verify clean test package package-deb package-rpm package-arch install uninstall parity

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oocut-linux-x86_64
	@sha256sum dist/oocut-linux-x86_64 > dist/oocut-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oocut-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*" -not -path "./qa*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

parity: $(BIN)
	@mkdir -p .ooda-cache .ooda-cache/parity
	$(OODA_COMPILER) build qa/parity/run.oo -o .ooda-cache/parity-run
	@chmod +x .ooda-cache/parity-run
	@.ooda-cache/parity-run

test: $(BIN) parity
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@echo "=== testing internal anchors ==="
	@./$(BIN) --test | grep -q "oocut: internal anchor tests PASSED" && echo "PASS: internal anchors"
	@echo "=== testing --demo view ==="
	@./$(BIN) --demo | grep -q "oocut 0.2.0" && echo "PASS: --demo view"
	@echo "=== testing --demo --json ==="
	@./$(BIN) --demo --json | grep -q '"tool": "oocut"' && echo "PASS: --demo --json"
	@echo "=== testing byte mode ==="
	@printf "abcdefgh\n" | ./$(BIN) -b 1-3 | grep -q "^abc$$" && echo "PASS: byte mode 1-3"
	@printf "abcdefgh\n" | ./$(BIN) -b 2,4-5 | grep -q "^bde$$" && echo "PASS: byte mode 2,4-5"
	@echo "=== testing character mode ==="
	@printf "αβγδε\n" | ./$(BIN) -c 1,3 | grep -q "^αγ$$" && echo "PASS: char mode UTF-8"
	@echo "=== testing field mode ==="
	@printf "u1:x:100:staff\nu2:x:200:dev\n" | ./$(BIN) -f 1,4 -d : | grep -q "^u1:staff$$" && echo "PASS: field mode"
	@echo "=== testing field mode with custom output delimiter ==="
	@printf "a:b:c\n" | ./$(BIN) -f 1,3 -d : --output-delimiter=" | " | grep -q "^a | c$$" && echo "PASS: custom output delimiter"
	@echo "=== testing delimiter suppression (-s) ==="
	@printf "has:colon\nplain line\n" | ./$(BIN) -f 1 -d : -s | grep -qv "plain line" && echo "PASS: -s suppression"
	@echo "=== testing complement flag ==="
	@printf "one:two:three\n" | ./$(BIN) -f 2 -d : --complement | grep -q "^one:three$$" && echo "PASS: complement flag"
	@echo "=== testing MCP initialize ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "protocolVersion" && echo "PASS: MCP initialize"
	@echo "=== testing MCP tools/list ==="
	@printf '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "cut_fields" && echo "PASS: MCP tools/list"
	@echo "=== testing MCP tools/call cut_fields ==="
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/call","name":"cut_fields","params":{"data":"a:b:c\\\\n1:2:3\\\\n","fields":"1,3","delimiter":":"}}\n' | ./$(BIN) --mcp | grep -q 'a:c' && echo "PASS: MCP cut_fields"
	@echo "=== testing MCP tools/call cut_bytes ==="
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/call","name":"cut_bytes","params":{"data":"abcdef\\\\n","bytes":"2-4"}}\n' | ./$(BIN) --mcp | grep -q 'bcd' && echo "PASS: MCP cut_bytes"
	@echo "=== testing MCP tools/call cut_characters ==="
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","name":"cut_characters","params":{"data":"αβγδ","characters":"1-2"}}\n' | ./$(BIN) --mcp | grep -q 'αβ' && echo "PASS: MCP cut_characters"
	@echo "=== testing MCP tools/call cut_slice ==="
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","name":"cut_slice","params":{"data":"x,y,z\\\\n","spec":"2","delimiter":","}}\n' | ./$(BIN) --mcp | grep -q 'y' && echo "PASS: MCP cut_slice"
	@echo "=== testing MCP tools/call cut_demo ==="
	@printf '{"jsonrpc":"2.0","id":7,"method":"tools/call","name":"cut_demo"}\n' | ./$(BIN) --mcp | grep -q 'agent' && echo "PASS: MCP cut_demo"
	@echo "ALL TESTS PASSED"

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oocut
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oocut-uninstall
	@echo "installed oocut and oocut-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oocut $(DESTDIR)$(BINDIR)/oocut-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oocut $(HOME)/.config/oocut; echo "purged user cache and config"; fi
	@echo "uninstalled oocut and oocut-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oocut
	@chmod 0755 dist/deb-root/usr/bin/oocut
	@cp uninstall.sh dist/deb-root/usr/bin/oocut-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oocut-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oocut_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oocut_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oocut-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oocut.spec > ~/rpmbuild/SPECS/oocut.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oocut.spec
	@cp ~/rpmbuild/RPMS/x86_64/oocut-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/oocut
	@chmod 0755 dist/arch-pkg/usr/bin/oocut
	@cp uninstall.sh dist/arch-pkg/usr/bin/oocut-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/oocut-uninstall
	@printf "pkgname = oocut\npkgbase = oocut\npkgver = $(VERSION)-1\npkgdesc = Byte, character, and delimiter-aware field stream extractor in pure openOODA.\nurl = https://github.com/openOODA-tools/oocut\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = oocut\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/oocut-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/oocut-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cd dist && sha256sum oocut* > checksums.txt 2>/dev/null || true
	@echo "built all packages and dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
