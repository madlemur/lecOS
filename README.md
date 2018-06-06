# kOS-scripts
kOS scripts for Kerbal Space Program
---
I have to give heaping amounts of thanks and gratitude to Gaiiden and gisikw for making their code available for everyone. They are the core of how my missions are scripted. I hope to be able to contribute something to the community that will make playing KSP more fun for someone out there.

Despite objections to the contrary, the maths of orbital mechanics often escapes me (like a probe core on a 'Flea' SRB from Minmus). This means that there are some brute-force attempts to calculate values that are probably simple (for Wolfram-Alpha or MatLab) to reduce enough to function in kOS. If anyone sees something like this, and would like to correct me, please do! Open an issue, submit a pull request...

# v0.1.0
boot/new_boot.ks    - the LEC bootloader, includes all the fixin's for library loading and I/O
ops_loader.ks       - the LEC ops loader, bootstraps the ops file for the current craft, includes pulling from backups when needed
template.op.ks      - a sample ops file, in this case a mission_runner mission; this pre-loads all the libraries you need and starts things off
Missions/template_mission.ks - create a craft with enough dV and a kOS CPU, name it "template", and it should put you at 300kM by 15deg with a LAN of 25
mission_runner.ks   - Heart of the beast, the event loop
launcher.ks         - functions to aid and abet attempts to overcome gravity in very specific ways
maneuver.ks         - functions to make sure you go that-a-way when you want to
navigate.ks         - functions to help you find your friends and debtors in space
event_lib.ks        - functions to help get things done around the craft; right now, it pushes the big red staging button

These require unix-y environments to run in. I use Cygwin, but Linux or MacOS would probably work, provided you have make and sed
Makefile            - gnu Make makefile that strips comments and unneeded whitespace out of scripts, and will even move them to my KSP folder
packer.sed          - the sed script that does most of the aforementioned comment and whitespace stripping

everything else     - bits and bobs of scripts and missions based on similar frameworks. most don't work, but I keep them around for inspiration
