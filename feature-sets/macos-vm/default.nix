# Intel macOS 15 VM in Docker (dockurr/macos), with SSH on localhost:2223 and ~/macshare as a 9p share.
{
  systemImports = [
    ./system
  ];

  userImports = [
    ./user
  ];
}
