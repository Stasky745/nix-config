{ modules, mailerlite, ... }:
{
  imports = with modules; [
    apps
    base
    mailerlite.modules.darwin.defaults
  ];
}
