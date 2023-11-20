#
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
#

Name:       harbour-hydrogen

# >> macros
# << macros

Summary:    hydrogen, a matrix client
Version:    0.4.1
Release:    1
Group:      Qt/Qt
License:    LICENSE
#BuildArch:  noarch
URL:        https://github.com/thigg/sfos-hydrogen
Source0:    %{name}-%{version}.tar.bz2
Source1:    release.zip
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   sailfish-components-webview-qt5
Requires(post): systemd
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  pkgconfig(sailfishwebengine)
BuildRequires:  desktop-file-utils
BuildRequires:  qt5-qttools-linguist

%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}
pushd hydrogen && unzip %{SOURCE1} && popd

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%preun
# >> preun
%systemd_preun booster-browser@%{name}.service
# << preun

%post
# >> post
%systemd_post booster-browser@%{name}.service
systemctl-user start booster-browser@%{name}.service ||:
# << post

%postun
# >> postun
%systemd_postun booster-browser@%{name}.service
# << postun

%files
%defattr(0644,root,root,-)
%attr(0755,root,root) %{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_userunitdir}/user-session.target.d/50-%{name}.conf
# >> files
# << files

%changelog
