-------------------------------------------------
Daewoo CPC-400/400S MSX2/MSX2+ Conversion Project
Created and Published by RBSC in 2026
Special thanks to Max Vlasov [Meteor-M]
-------------------------------------------------

These are fixed and optimized firmwares for GAL chips U33 and U46 that need to be installed for the upgrade for the following configurations:

Config_A: MSX2, all BIOSes are in slot 0, on-board RAM is in slot 0.2.
Config_B: MSX2, all BIOSes are in slot 0, on-board RAM is disabled, external RAM is in unexpanded slot 3.
Config_C: MSX2, MSX BIOS and BASIC are in slot 0, SUBROM is in slot 3.0, disk BIOS is in slot 0.3, on-board RAM is disabled, external RAM is in expanded slot 3.2.
Config_D: MSX2+, MSX BIOS and BASIC are in slot 0, disk BIOS is in slot 0.3, SUBROM and KANJI drivers are in slot 3.0, on-board RAM is disabled, external RAM is in expanded slot 3.2, FMPAC is in slot 3.1.

IMPORTANT!
If you would like to keep the disk ROM in slot 2 for compatibility with Carnivore2/2+, please use the U33_DSL2.JED file instead of U33.JED.

Use the TL866, T46 or other EEPROM programmer to flash JEDs files into two GAL16V8D chips.

The modifications were done by Meteor-M and Wierzbowsky [RBSC].
