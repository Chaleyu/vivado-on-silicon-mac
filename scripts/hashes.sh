# This file contains the hashes for the different versions
# of the Vivado installer.
# The first 4 digits are the year part of the version number
# The 5th digit is the subversion, e.g. 202210 corresponds
# to the version 2022.1.

# This script needs to be sourced into other scripts or
# be run explicitly with an interpreter since it has no shebang

# AMD retires the online files used by the web installer for older releases.
# Web installers below this version code may fail while downloading their
# payload; for those releases the SFD (full) installer is the reliable option.
web_installer_warn_before=202410

# hashes for the web installer
declare -A web_hashes=(
    ["a6b118fffbcfdc7376c2640f276e2ca9"]=202110
    ["9bf473b6be0b8531e70fd3d5c0fe4817"]=202220
    ["e47ad71388b27a6e2339ee82c3c8765f"]=202310
    ["b8c785d03b754766538d6cde1277c4f0"]=202320
    ["8b0e99a41b851b50592d5d6ef1b1263d"]=202410
    # 2024.2: original publication and the currently published Linux installers
    ["20c806793b3ea8d79273d5138fbd195f"]=202420
    ["6be7a694bc631e02862e173f94165f88"]=202420
    # 2024.2.2 patch installer
    ["330335716f144e5be7a29279bfe41909"]=202420
    # MD5s below are taken from AMD's PGP-signed installer .digests files.
    ["d454c48fc36481c21d3255b23f9b6c73"]=202510
    # 2025.1.1 patch installer — maps to the same install config as 2025.1
    ["7d2995c898c36f7067ddafbd52f46de8"]=202510
    ["abe838aa2e2d3d9b10fea94165e9a303"]=202520
    # 2025.2.1 patch installer — maps to the same install config as 2025.2
    ["85ac3a5975ec7906224896fdce842f21"]=202520
    ["02850e72c78859bbcd6485846940921e"]=202610
    # 2026.1.1 patch installer — maps to the same install config as 2026.1
    ["b613da299813b0292a4cc0e0b0bbf4b8"]=202610
)
# hashes for the full installer (SFD)
declare -A sfd_hashes=(
   # 2022.1 has no entry in install_configs/, so it is not offered as an SFD option.
   # ["0bf810cf5eaa28a849ab52b9bfdd20a5"]=202210
   ["4b4e84306eb631fe67d3efb469122671"]=202220
   ["f2011ceba52b109e3551c1d3189a8c9c"]=202310
   ["64d64e9b937b6fd5e98b41811c74aab2"]=202320
   ["372c0b184e32001137424e395823de3c"]=202410
   # 2024.2 and 2024.2.2 SFD installers (original and currently published .tar)
   ["0ca31a787bbdff82b55213522e604446"]=202420
   ["3535edd134fc336c6c44de6ba5ef1dc5"]=202420
   ["f34a4d815a3c58aa29053feaab386b4b"]=202420
   # 2025.x/2026.x SFD installers are .tar files; MD5s from AMD's signed digests
   ["144b21e7a231081821d13f85495dd809"]=202510
   ["06ab8656082d38c214ecda01ebdff697"]=202510
   ["fdae748783af560aa005b62dd7ef4b26"]=202520
   ["11183f1b399d176a4ff4424a7c0603f5"]=202520
   ["b577835d4304f07e40292c51a4018482"]=202610
   ["0c0df882135fc3258bb598a7551fe36e"]=202610
)
