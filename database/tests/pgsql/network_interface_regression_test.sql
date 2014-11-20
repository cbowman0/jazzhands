-- Copyright (c) 2014 Todd Kover
-- All rights reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- $Id$


\set ON_ERROR_STOP

\t on

CREATE OR REPLACE FUNCTION validate_network_interface_triggers() 
RETURNS BOOLEAN AS $$
DECLARE
	_tally		integer;
	_dev1		device%ROWTYPE;
	_ni			network_interface%ROWTYPE;
	_blk		netblock%ROWTYPE;
	_nb			netblock%ROWTYPE;
	_other		netblock%ROWTYPE;
BEGIN
	RAISE NOTICE 'Cleanup Records from Previous Tests';
	DELETE FROM network_interface where network_interface_name like 'JHTEST%';
	DELETE FROM network_interface where description like 'JHTEST%';
	DELETE FROM device where device_name like 'JHTEST%';
	DELETE from netblock where description like 'JHTEST%';
	DELETE from site where site_code like 'JHTEST%';

	RAISE NOTICE 'Inserting Test Data...';
	INSERT INTO site (site_code,site_status) values ('JHTEST01','ACTIVE');


	INSERT INTO device (
		device_type_id, device_name, device_status, site_code,
		service_environment_id, operating_system_id,
		ownership_status, is_monitored
	) values (
		1, 'JHTEST one', 'up', 'JHTEST01',
		(select service_environment_id from service_environment
		where service_environment_name = 'production'),
		0,
		'owned', 'Y'
	) RETURNING * into _dev1;


	INSERT INTO NETBLOCK (ip_address, netblock_type,
			is_single_address, can_subnet, netblock_status,
			description
	) VALUES (
		'172.31.29.42/24', 'adhoc',
			'Y', 'N', 'Allocated',
			'JHTEST _blk'
	) RETURNING * INTO _other;

	INSERT INTO NETBLOCK (ip_address, netblock_type,
			is_single_address, can_subnet, netblock_status,
			description
	) VALUES (
		'172.31.30.0/24', 'default',
			'N', 'N', 'Allocated',
			'JHTEST _blk'
	) RETURNING * INTO _blk;

	INSERT INTO NETBLOCK (ip_address, netblock_type,
			is_single_address, can_subnet, netblock_status,
			description
	) VALUES (
		'172.31.30.1/24', 'default',
			'Y', 'N', 'Allocated',
			'JHTEST _nb'
	) RETURNING * INTO _nb;

	RAISE NOTICE 'Testing to see if is_single_address = Y works...';
	INSERT INTO network_interface (
		device_id, network_interface_name, network_interface_type,
		description,
		should_monitor, netblock_id
	) VALUES (
		_dev1.device_id, 'JHTEST0', 'broadcast', 'Y',
		'JHTEST0',
		_nb.netblock_id
	) RETURNING * INTO _ni;
	RAISE NOTICE '... it did!';

	RAISE NOTICE 'Testing to see if is_single_address = N fails...';
	BEGIN
		INSERT INTO network_interface (
			device_id, network_interface_name, network_interface_type,
			description,
			should_monitor, netblock_id
		) VALUES (
			_dev1.device_id, 'JHTEST1', 'broadcast', 'Y',
			'JHTEST1',
			_blk.netblock_id
		) RETURNING * INTO _ni;
		RAISE EXCEPTION '... it did not (!)';
	EXCEPTION WHEN foreign_key_violation THEN
		RAISE NOTICE '... It did, as expected';
	END;

	RAISE NOTICE 'Testing to see if network_interface_type != default fails...';
	BEGIN
		INSERT INTO network_interface (
			device_id, network_interface_name, network_interface_type,
			description,
			should_monitor, netblock_id
		) VALUES (
			_dev1.device_id, 'JHTEST2', 'broadcast', 'Y',
			'JHTEST2',
			_other.netblock_id
		) RETURNING * INTO _ni;
		RAISE EXCEPTION '... it did not (!)';
	EXCEPTION WHEN foreign_key_violation THEN
		RAISE NOTICE '... It did, as expected';
	END;

	RAISE NOTICE 'Cleanup Records';
	DELETE FROM network_interface where network_interface_name like 'JHTEST%';
	DELETE FROM network_interface where description like 'JHTEST%';
	DELETE FROM device where device_name like 'JHTEST%';
	DELETE from netblock where description like 'JHTEST%';
	DELETE from site where site_code like 'JHTEST%';
	RETURN true;
END;
$$ LANGUAGE plpgsql;

-- set search_path=public;
SELECT jazzhands.validate_network_interface_triggers();
-- set search_path=jazzhands;
DROP FUNCTION validate_network_interface_triggers();

\t off
