{ modules, ... }:
{
  imports = with modules; [
    apps
    base
  ];
}
