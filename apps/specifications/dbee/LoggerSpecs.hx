package specifications.dbee;

class LoggerSpecs extends hxspec.Specification
{
	function before() {
	}
	
	function after() {
	}
	
	function Should_run_in_its_own_thread(){
		
	}
	
	function Should_snapshot_full_state_when_log_gets_big(){
		
	}
	
	function Should_snapshot_when_load_is_low(){
		
	}
	
	function Should_snapshot_to_a_new_log_file(){
		
	}
	
	function Should_allow_new_objects_to_be_added_to_the_transaction(){
		
	}
	
	function Should_resume_state_from_last_complete_snapshot(){
		
	}
	
	function Should_resume_state_from_last_complete_snapshot_and_incomplete_snapshot_when_incomplete_snapshot_is_found(){
		
	}
	
	function Should_discard_incomplete_blocks(){
		
	}
}

class MulticastLoggerSpecs extends LoggerSpecs
{
	function Should_allow_lockless_global_state_snapshotting(){
		
	}
	
	function Should_multicast_when_local_snapshot_is_complete(){
		
	}
	
	/** Some machine crashed and needs all changes since it crashed... **/
	function Should_request_for_global_snapshot_when_resuming_from_incomplete_state(){
		
	}
	
	function Should_send_changes_since_global_snapshot_start(){
		
	}
}

/*
	- Ping elke 'buddy'-node om de zoveel seconden om bij te houden welke nog levend zijn.

	klant.naam = 'jan';
	klant.save();
		1) Schrijf wijziging naar logfile
		1) Stuur wijziging naar buddy nodes
		
		2) Wacht op OK van alle levende buddy nodes
		   Timeout na "laatste ping tijd"x100 
		   ( Ping 1ms = 100ms, ping 10ms = 1000ms )
		
		3) Schrijf OK|NodeID|Table|ID
		3) Sla wijziging op in geheugen
		

	Machine 1 crashed
	  - Laad logfile
	  - Houd bij welke records gewijzigd zijn
	  - Ziet een aantal writes waar niet elke node met OK op heeft gereageerd
	  - Vraagt aan minst belastte buddy om global snapshot
	
	
	Global snapshot
	  - 
	
	


	klant.naam = 'jan';
	klant.save();
		-- Multicast de wijziging
		-- Wacht op OK van alle nodes die dit record bijhouden
			Wat als OK nooit verzonden wordt omdat machine plat ging?
		-- Schrijf naar logfile ?
	
	machine 1: klant.naam = 'jan';
	machine 2: klant.naam = 'Jan';
	klant.save() tegelijkertijd op beide machines
		-- Reply met DISCARD
		-- Schrijf niet naar log maar stuur error
	

	http://en.wikipedia.org/wiki/Three-phase_commit_protocol
	
	http://www.cs.chalmers.se/~phs/warp/project.html

	klant.adres.save();
		1 Lock dit record
		2 serialize de wijziging naar string
		3 -- parallel:
			- stuur naar logger
			- multicast de wijziging: RFS | Tabel | ID | veld | waarde
		4 Unlock record zodra alle nodes gereageerd hebben met OK
		
		1)	RequestForSave voor hetzelfde record komt binnen terwijl er gesaved wordt
			- Reply met COLLISION | Tabel | ID | veld | waarde
			- Throw exception en vraag user welke te bewaren?

	var k = DB.klanten.get(0);
	var t = Transaction.start([k]);
	
	k.blabla.value = 1;
	k.adres.r.value = 10;
	
	k.save();
	
	t.isValid(); // ?
	t.commit();
	
	var t = new Transaction();
	var k = new Klant();
	t.add(k);
	k.save();
	t.commit();
*/
