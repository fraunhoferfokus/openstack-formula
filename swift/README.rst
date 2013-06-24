
swift/

  - **init.sls**: includes all other states
  - **config.sls**: handles configuration files, uses
    *pillar['swift-user']* and *pillar['swift-group']*.
  - **packages.sls**: Installs packages needed for various swift components.
    The actual package lists come from *pillar['swift-pkgs']['base']* and so on
  - **swift.conf**: Template for */etc/swift/swift.conf*, 
    used by *config.sls* and uses *pillar['swift-hash']* itself.
  - **devices.sls**: Manages the backend devices used for Swift. The devices
    have to be specified in *pillar['swift-devices']* but are not formated only
    mounted yet (so this state will fail if the devices aren't formated with 
    the expected filesystem).
