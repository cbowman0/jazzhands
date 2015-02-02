DO $$
BEGIN
	PERFORM * FROM val_slot_function WHERE slot_function = 'serial';

	IF NOT FOUND THEN
		INSERT INTO val_slot_function (slot_function, description) VALUES
			('serial', 'Serial port');

		--
		-- Serial slot types
		--
		INSERT INTO val_slot_physical_interface
			(slot_physical_interface_type, slot_function)
		SELECT
			unnest(ARRAY[
				'RJ45',
				'DB9',
				'DB25',
				'virtual'
			]),
			'serial';

		INSERT INTO slot_type 
			(slot_type, slot_physical_interface_type, slot_function,
			 description, remote_slot_permitted)
		VALUES
			('RJ45 serial', 'RJ45', 'serial', 'RJ45 serial port', 'Y'),
			('DB9 serial', 'DB9', 'serial', 'DB9 serial port', 'Y'),
			('DB25 serial', 'DB25', 'serial', 'RJ45 serial port', 'Y'),
			('virtual serial', 'DB25', 'serial', 'virtual serial port', 'Y');
	END IF;
END $$ language plpgsql
