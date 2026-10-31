# Local Mkosi raw-GPT DDI. This is separate from the bootc install-to-disk path.
[group('build')]
mkosi-ddi:
    mkosi --directory=mkosi/ddi build

[group('build')]
mkosi-ddi-clean:
    mkosi --directory=mkosi/ddi clean
