-- Copyright (c) 2015, Todd M. Kover, Matthew D. Ragan
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
--
-- $Id$
--

--
-- XXX NOTE: need to migrate network_interface.physical_port_id
--

create or replace view v_layer1_connection
AS
SELECT	
	icc.inter_component_connection_id  AS layer1_connection_id,
	icc.slot1_id			AS physical_port1_id,
	icc.slot2_id			AS physical_port2_id,
	icc.circuit_id,
	'NOTYET'			AS baud,
	'NOTYET'			AS data_bits,
	'NOTYET'			AS stop_bits,
	'NOTYET'			AS parity,
	'NOTYET'			AS flow_control,
	'NOTYET'			AS tcpsrv_device_id,
	'NOTYET'			AS is_tcpsrv_enabled,
	icc.data_ins_user,
	icc.data_ins_date,
	icc.data_upd_user,
	icc.data_upd_date
FROM inter_component_connection icc
	INNER JOIN slot s1 ON icc.slot1_id = s1.slot_id
	INNER JOIN slot_type st1 ON st1.slot_type_id = s1.slot_type_id
	INNER JOIN slot s2 ON icc.slot2_id = s2.slot_id
	INNER JOIN slot_type st2 ON st2.slot_type_id = s2.slot_type_id
 WHERE  st1.slot_function in ('network', 'serial', 'patchpanel')
	OR
 	st1.slot_function in ('network', 'serial', 'patchpanel')
;
