/**
 * (C) Copyright 2016 Intel Corporation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * GOVERNMENT LICENSE RIGHTS-OPEN SOURCE SOFTWARE
 * The Government's rights to use, modify, reproduce, release, perform, display,
 * or disclose this software are subject to the terms of the Apache License as
 * provided in Contract No. B609815.
 * Any reproduction of computer software, computer software documentation, or
 * portions thereof marked with this legend must also reproduce the markings.
 */
/**
 * Tier-related client library items that do not belong in the API.
 */
#ifndef __DC_TIER_H__
#define __DC_TIER_H__

#include <daos/common.h>
#include <daos/tse.h>
#include <daos_types.h>

int  dc_tier_init(void);
void dc_tier_fini(void);
int dc_tier_ping(uint32_t ping_val, tse_task_t *task);
int
dc_tier_fetch_cont(daos_handle_t poh, const uuid_t cont_id,
		   daos_epoch_t fetch_ep, daos_oid_list_t *obj_list,
		   tse_task_t *task);
/**
 * Inter-tier connect, warm-to-cold
 * /param warm_id	uuid of the warm pool
 * /param warm_grp	srv_grp of the warmer tier
 * /param cold_id	uuid of the colder tier pool
 * /param cold_grp	srv_grp of the colder tier
 * /param task		daos task
 *
 * /return		integer error code
 */
int dc_tier_connect(const uuid_t warm_id, const char *warm_grp,
		    tse_task_t *task);

int dc_tier_register_cold(const uuid_t colder_id, const char *colder_grp,
			  char *tgt_grp, tse_task_t *task);

#endif /* __DC_TIER_H__ */
