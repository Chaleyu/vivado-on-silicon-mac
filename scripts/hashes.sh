# This file contains the hashes for the different versions
# of the Vivado installer.
# The first 4 digits are the year part of the version number
# The 5th digit is the subversion, e.g. 202210 corresponds
# to the version 2022.1.

# This script needs to be sourced into other scripts or
# be run explicitly with an interpreter since it has no shebang

# AMD retires the web installers of older releases (the small .bin that
# downloads its payload at install time). Those installers no longer work, so
# their hashes are not listed and setup.sh rejects them; use the SFD (full)
# installer (.tar / .tar.gz) for these releases instead.
web_installer_unsupported_before=202410

# hashes for the web installer (.bin). Only releases whose web installers are
# still supported are listed; older releases must use the SFD installer.
declare -A web_hashes=(
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
   # 2022.1 SFD installer (verified against AMD's signed .digests file)
   ["0bf810cf5eaa28a849ab52b9bfdd20a5"]=202210
   # Old SFD installers (.tar.gz); MD5s from AMD's PGP-signed .digests files
   ["e2b2762964ef5f014591b13d77d823ab"]=201920
   ["3a88784dbed40ab1008c28b040717f72"]=202110
   ["c6f91186f332528a7b74a6a12a759fb6"]=202120
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
