-- Copyright (c) 2021 Todd Kover
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
SAVEPOINT service_base_regression;

\ir ../../ddl/schema/pgsql/create_service_base_triggers.sql

SAVEPOINT pretest;

--
-- Trigger tests
--
CREATE OR REPLACE FUNCTION service_base_regression() RETURNS BOOLEAN AS $$
DECLARE
	_r	RECORD;
BEGIN
	RAISE NOTICE 'service_base_regression: Begin';

	INSERT INTO val_service_namespace ( service_namespace ) 
		VALUES ('altnamespace1');

	INSERT INTO val_service_type ( service_type, service_namespace ) VALUES
		('jhtype1', 'default'),
		('jhtype2', 'default'),
		('jhtype3', 'altnamespace1'),
		('jhtype4', 'altnamespace1');


	RAISE NOTICE 'Checking if namespace uniquness works on INSERT';
	BEGIN
		INSERT INTO service (service_name, service_type) VALUES
			('unique1', 'network');
		BEGIN
			INSERT INTO service (service_name, service_type) VALUES
				('unique1', 'socket');
		EXCEPTION WHEN unique_violation THEN
			RAISE EXCEPTION '%', SQLERRM USING ERRCODE = 'JH999';
		END;
		RAISE EXCEPTION 'Ugh, It worked!';
	EXCEPTION WHEN SQLSTATE 'JH999' THEN
		RAISE NOTICE '... It did (%)', SQLERRM;
	END;

	RAISE NOTICE 'Checking if namespace uniquness works on UPDATE';
	BEGIN
		INSERT INTO service (service_name, service_type) VALUES
			('unique1', 'network'),
			('unique2', 'socket');
		BEGIN
			UPDATE service 
			SET service_name = 'unique1' 
			WHERE service_name = 'unique2' 
			AND service_type = 'socket';
		EXCEPTION WHEN unique_violation THEN
			RAISE EXCEPTION '%', SQLERRM USING ERRCODE = 'JH999';
		END;
		RAISE EXCEPTION 'Ugh, It worked!';
	EXCEPTION WHEN SQLSTATE 'JH999' THEN
		RAISE NOTICE '... It did (%)', SQLERRM;
	END;

	RAISE NOTICE 'Checking if changing namespaces fails as expected';
	BEGIN
			INSERT INTO service (service_name, service_type) VALUES
				('unique1', 'jhtype1'),
				('unique1', 'jhtype3');
		BEGIN
			UPDATE val_service_type 
			SET service_namespace = 'default'
			WHERE service_type = 'jhtype3'
			RETURNING * INTO _r;
		EXCEPTION WHEN unique_violation THEN
			RAISE EXCEPTION '%', SQLERRM USING ERRCODE = 'JH999';
		END;
		RAISE EXCEPTION 'Ugh, It worked! %', to_jsonb(_r);
	EXCEPTION WHEN SQLSTATE 'JH999' THEN
		RAISE NOTICE '... It did (%)', SQLERRM;
	END;

	RAISE NOTICE 'Checking if changing namespaces works as expected';
	BEGIN
		INSERT INTO service (service_name, service_type) VALUES
			('unique1', 'jhtype1'),
			('unique2', 'jhtype3');
		UPDATE val_service_type 
		SET service_namespace = 'default'
		WHERE service_type = 'jhtype3'
		RETURNING * INTO _r;
		RAISE NOTICE 'success!';
	EXCEPTION WHEN SQLSTATE 'JH999' THEN
		RAISE NOTICE '... It did (%)', SQLERRM;
	END;


	RAISE NOTICE 'Cleaning up...';
	RAISE NOTICE 'END service_base_regression...';
	RETURN true;

END;
$$ LANGUAGE plpgsql;

-- set search_path=public;
SELECT service_base_regression();
-- set search_path=jazzhands;
DROP FUNCTION service_base_regression();

ROLLBACK TO service_base_regression;

\t off
