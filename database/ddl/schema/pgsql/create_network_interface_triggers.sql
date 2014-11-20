/*
 * Copyright (c) 2014 Todd Kover
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION net_int_nb_single_address() 
RETURNS TRIGGER AS $$
DECLARE
	_tally	INTEGER;
BEGIN
	IF NEW.netblock_id IS NOT NULL THEN
		select count(*)
		INTO _tally
		FROM netblock
		WHERE netblock_id = NEW.netblock_id
		AND is_single_address = 'Y'
		AND netblock_type = 'default';

		IF _tally = 0 THEN
			RAISE EXCEPTION 'network interfaces must refer to single ip addresses of type default (%,%)', NEW.network_interface_id, NEW.netblock_id
				USING errcode = 'foreign_key_violation';
		END IF;
	END IF;
	RETURN NEW;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_net_int_nb_single_address ON network_interface;
CREATE TRIGGER trigger_net_int_nb_single_address 
	BEFORE INSERT OR UPDATE OF netblock_id
	ON network_interface 
	FOR EACH ROW 
	EXECUTE PROCEDURE net_int_nb_single_address();

---------------------------------------------------------------------------
-- Transition triggers
---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION net_int_netblock_to_nbn_compat_before() 
RETURNS TRIGGER AS $$
DECLARE
	_tally	INTEGER;
BEGIN
	IF TG_OP = 'DELETE' THEN
		DELETE from network_interface_netblock
			WHERE network_interface_id = OLD.network_interface_id
			AND netblock_id = OLD.netblock_id;
		RETURN OLD;
	ELSE -- update
		IF OLD.netblock_id IS NULL and NEW.netblock_id IS NOT NULL THEN
			DELETE from network_interface_netblock
				WHERE network_interface_id = OLD.network_interface_id
				AND netblock_id = OLD.netblock_id;
		END IF;
		RETURN NEW;
	END IF;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_net_int_netblock_to_nbn_compat_before
ON network_interface;
CREATE TRIGGER trigger_net_int_netblock_to_nbn_compat_before
	BEFORE DELETE OR UPDATE OF network_interface_id,  netblock_id
	ON network_interface 
	FOR EACH ROW 
	EXECUTE PROCEDURE net_int_netblock_to_nbn_compat_before();

CREATE OR REPLACE FUNCTION net_int_netblock_to_nbn_compat_after() 
RETURNS TRIGGER AS $$
DECLARE
	_tally	INTEGER;
BEGIN
	IF TG_OP = 'INSERT' THEN
		INSERT INTO network_interface_netblock
			(network_interface_id, netblock_id)
		VALUES
			(NEW.network_interface_id, NEW.netblock_id);
	ELSIF TG_OP = 'UPDATE'  THEN
		IF OLD.netblock_id is NULL and NEW.netblock_ID is NOT NULL THEN
			INSERT INTO network_interface_netblock
				(network_interface_id, netblock_id)
			VALUES
				(NEW.network_interface_id, NEW.netblock_id);
		ELSIF OLD.netblock_id IS NOT NULL and NEW.netblock_ID is NOT NULL THEN
			UPDATE network_interface_netblock
				SET network_interface_id = NEW.network_interface_Id,
					netblock_id = NEW.netblock_id
					WHERE network_interface_id = OLD.network_interface_id
					AND netblock_id = OLD.netblock_id;
		END IF;
	END IF;
	RETURN NEW;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_net_int_netblock_to_nbn_compat_after
ON network_interface;
CREATE TRIGGER trigger_net_int_netblock_to_nbn_compat_after
	AFTER INSERT OR UPDATE OF network_interface_id, netblock_id
	ON network_interface 
	FOR EACH ROW 
	EXECUTE PROCEDURE net_int_netblock_to_nbn_compat_after();

---------------------------------------------------------------------------
-- End of transition triggers
---------------------------------------------------------------------------
