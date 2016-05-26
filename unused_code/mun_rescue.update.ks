// Mun Rescue boot script
copy lib_auto from 0.
copy lib_nav2 from 0.
copy launch from 0.

run lib_nav2.
run lib_auto.

run launch(0,150000).
