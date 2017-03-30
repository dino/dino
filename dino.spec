# To build current git tree into RPM using tito:
# - Run `tito build --rpm --test`

# To build latest tagged release from git into RPM using tito:
# - Run `tito build --rpm`

# To build older tagged release from git into RPM using tito:
# - Run `tito build --rpm --tag=vVERSION`

# To build a tagged release from git into RPM using rpmbuild:
# - Put version number into Version
# - Run `spectool -g -R dino.spec`
# - Run `rpmbuild -bb dino.spec`

# To build a specific git commit into RPM using rpmbuild:
# - Put commit id into COMMIT_ID_HERE
# - Use second (currently commented) line for Release, Source0 and %setup
# - Run `spectool -g -R dino.spec`
# - Run `rpmbuild -bb dino.spec`

%global commit COMMIT_ID_HERE
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:		dino
Version:	0
Release:	0%{?dist}
#Release:	0.git.%{shortcommit}%{?dist}
Summary:	Modern Jabber/XMPP Client using GTK+/Vala
License:	GPLv3
URL:		https://github.com/dino/dino
Source0:	https://github.com/dino/dino/archive/v%{version}.zip
#Source0:	https://github.com/dino/dino/archive/%{commit}.zip
BuildRequires:	vala >= 0.30
BuildRequires:	vala-tools >= 0.30
BuildRequires:	cmake
BuildRequires:	git
BuildRequires:	ninja-build
BuildRequires:	desktop-file-utils
BuildRequires:	pkgconfig(gthread-2.0)
BuildRequires:	pkgconfig(glib-2.0) >= 2.38
BuildRequires:	pkgconfig(gio-2.0)
BuildRequires:	pkgconfig(gtk+-3.0) >= 3.22
BuildRequires:	pkgconfig(gee-0.8) >= 0.10
BuildRequires:	pkgconfig(libnotify)
BuildRequires:	pkgconfig(sqlite3)
BuildRequires:	pkgconfig(openssl)
BuildRequires:	gpgme-devel
Requires:	hicolor-icon-theme

%description
Dino is an instant messaging client for the Jabber/XMPP network,
providing a unique and modern user experience based on the latest
technology from the GNOME project. Dino is still in early
development and has limited features, but already has basic support
for XMPP's latest encryption features. Future versions will provide
a plug-in API, so that developers can easily add new optional
features.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    devel
The %{name}-devel package contains libraries and header files for
developing plugins for %{name}.

%prep
%setup -n "dino-v%{version}"
#%setup -n "dino-%{commit}"

%build
%configure
make

%install
make install DESTDIR="%{buildroot}"
desktop-file-validate %{buildroot}%{_datadir}/applications/dino.desktop

%post
update-desktop-database &>/dev/null || :
touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :

%postun
update-desktop-database &> /dev/null || :
if [ $1 -eq 0 ] ; then
  touch --no-create %{_datadir}/icons/hicolor &>/dev/null
  gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor &>/dev/null || :
  glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :
fi

%posttrans
gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor &>/dev/null || :
glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :

%files
%license LICENSE
%doc README.md
%{_bindir}/dino
%{_libdir}/libdino.so
%{_libdir}/libqlite.so
%{_libdir}/libxmpp-vala.so
%{_datadir}/dino
%{_datadir}/applications/dino.desktop
%{_datadir}/glib-2.0/schemas/dino.gschema.xml
%{_datadir}/icons/hicolor/*/apps/dino.*
%{_datadir}/icons/hicolor/*/apps/dino-*
%{_datadir}/icons/hicolor/*/status/dino-*

%files devel
%{_includedir}/*
%{_datadir}/vala/vapi

%changelog
* Fri Mar 24 2017 - 0.0
- Initial version
