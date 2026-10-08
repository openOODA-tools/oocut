Name:           oocut
Version:        0.2.0
Release:        1%{?dist}
Summary:        Byte, character, and delimiter-aware field extractor with negative-index slicing.
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oocut
Source0:        oocut-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oocut is a sovereign, capability-bounded column, byte, character,
and delimiter-aware field stream extractor written in pure openOODA,
featuring zero ambient authority, terminal themes, and a streaming
Model Context Protocol (MCP) JSON-RPC 2.0 stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oocut
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oocut-uninstall

%files
/usr/bin/oocut
/usr/bin/oocut-uninstall

%changelog
* Wed Oct 08 2026 openOODA-tools <ops@openooda.org> - 0.2.0-1
- Elevate oocut to v0.2.0 sovereign field extractor with streaming MCP
