-- Copyright (c) 2014, Todd M. Kover
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
-- This query pulls out all the device collection overrides
--
-- NOTE:  This view does not attempt to validate if a user has any
-- association with a device collection, just if a user is there, what
-- properties are set.  Its primary use is by other views.
--
CREATE OR REPLACE VIEW v_unix_account_overrides
AS
SELECT device_collection_id, account_id, 
	array_agg(setting ORDER BY rn) AS setting
FROM (
	SELECT *, row_number() over () AS rn FROM (
		SELECT device_collection_id, account_id,
				unnest(ARRAY[property_name, property_value]) AS setting
		FROM (
			SELECT  dchd.device_collection_id, 
					acae.account_id,
					p.property_name, 
					coalesce(p.property_value, 
						p.property_value_password_type) as property_value,
					row_number() OVER (partition by 
							dchd.device_collection_id,
							acae.account_id,
							acpe.property_name
							ORDER BY dchd.device_collection_level, assign_rank,
								property_id
					) AS ord
			FROM    v_acct_coll_prop_expanded acpe
				INNER JOIN v_acct_coll_acct_expanded acae 
						USING (account_collection_id)
				INNER JOIN property p USING (property_id)
					INNER JOIN v_device_coll_hier_detail dchd
						ON dchd.parent_device_collection_id = 
							p.device_collection_id
			WHERE	p.property_type IN ('UnixPasswdFileValue', 
						'UnixGroupFileProperty',
						'MclassUnixProp')
			AND		p.property_name NOT IN 
					('UnixLogin','UnixGroup','UnixGroupMemberOverride')
		) dc_acct_prop_list
		WHERE ord = 1
	) select_for_ordering
) property_list
GROUP BY device_collection_id, account_id
;
