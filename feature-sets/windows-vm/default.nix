# Windows 11 dev VM in Docker (dockurr/windows), with SSH on localhost:2222 and ~/winshare as Z:.
{
  systemImports = [
    ./system
  ];

  userImports = [
    ./user
  ];
}
