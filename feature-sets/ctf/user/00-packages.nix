{pkgs, ...}: {
  home.packages = with pkgs; [
    # Reverse Engineering
    ghidra
    binwalk

    # Net Discovery
    netcat
    nmap
    masscan

    # Radio
    urh
    gnuradio

    # Exploits
    metasploit
    burpsuite
    sqlmap # SQL injection automation

    # Passwords
    john # John the Ripper, password cracker
    hashcat # GPU-accelerated password cracker
    aircrack-ng # WiFi key cracking
    hydra # Network logon cracker

    # Web
    amass # Subdomain enumeration
    gobuster # Directory and DNS brute forcing
    dirb # Web directory brute forcing
    nikto # Web server vulnerability scanner

    # General Pentesting / Utils
    enum4linux # SMB enumeration
    ettercap # Man-in-the-middle attack suite
    socat # Multipurpose bidirectional data relay
    exiftool # Metadata extractor
  ];
}
