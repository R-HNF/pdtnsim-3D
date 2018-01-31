demo:
	./run.pl -m Mobility::Voronoi -a Agent::P_BCAST -n 30 -M Monitor::SDL

dist:
	version=`ident dtnsim | tail -1 | awk '{ print $$3 }'`; \
	tar czvf dtnsim-$$version.tar.gz Agent/*.pm Makefile Mobility/*.pm Mobility/*/*.pm Monitor/*.pm dtnsim
