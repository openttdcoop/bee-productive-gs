
require("company.nut");

class BusyBeeClass extends GSController
{
    cargoes = null; // Cargoes of the game (index -> 'cid' number, 'freight' boolean, 'effect' on town).
    num_cargoes = 0;

    companies = null;

    function Start();
}

// Examine and store cargo types of the game.
function BusyBeeClass::ExamineCargoes()
{
    this.cargoes = {};
    this.num_cargoes = 0;

    for (local cid = 0; cid < 32; cid += 1) {
        if (!GSCargo.IsValidCargo(cid)) continue;

        local is_freight = GSCargo.IsFreight(cid);
        local town_effect = GSCargo.GetTownEffect(cid);
        this.cargoes[this.num_cargoes] <- {cid=cid, freight=is_freight, effect=town_effect};
        this.num_cargoes += 1;
    }
}

// Find cargo sources.
// @param cargo_id Cargo index (index in this.cargoes).
// @return List of resources that produce the requested cargo, list of
//      'ind' or 'town' number, 'prod' produced amount, 'transp' transported amount, and 'loc' location.
function BusyBeeClass::FindSources(cargo_id)
{
    local cargo = this.cargoes[cargo_id];
    local num_sources = 0;
    local sources = {};

    if (cargo.freight) {
        // For 'freight' cargoes, check the producing industries for sufficient available production.
        foreach (ind, _ in GSIndustryList_CargoProducing(cargo.cid)) {
            local prod_amount = GSIndustry.GetLastMonthProduction(ind, cargo.cid);
            if (prod_amount < 10) continue;
            local transp_amount = GSIndustry.GetLastMonthTransported(ind, cargo.cid);
            if (prod_amount - transp_amount < 10) continue;
            local loc = GSIndustry.GetLocation(ind);
            sources[num_sources] <- {ind=ind, prod=prod_amount, transp=transp_amount, loc=loc};
            num_sources += 1;
        }
    }
    if (cargo.effect != GSCargo.TE_NONE) {
        // For 'town effect' cargoes, check the towns for sufficient available production.
        foreach (town, _ in GSTownList()) {
            local prod_amount = GSTown.GetLastMonthProduction(town, cargo.cid);
            if (prod_amount < 10) continue;
            local transp_amount = GSTown.GetLastMonthSupplied(town, cargo.cid);
            if (prod_amount - transp_amount < 10) continue;
            local loc = GSTown.GetLocation(town);
            sources[num_sources] <- {town=town, prod=prod_amount, transp=transp_amount, loc=loc};
            num_sources += 1;
        }
    }
    return sources;
}

// Find destinations for the cargo.
// @param cargo_id Cargo index (index in this.cargoes).
// @param company Company to inspect.
// @return A list of destinations, tables 'ind' or 'town' id, and a 'loc' location.
function BusyBeeClass::FindDestinations(cargo_id, company)
{
    local cargo = this.cargoes[cargo_id];
    local num_dests = 0;
    local dests = {};

    if (cargo.freight) {
        // Assume all industries are willing to accept the cargo.
        foreach (ind, _ in GSIndustryList_CargoAccepting(cargo.cid)) {
            local loc = GSIndustry.GetLocation(ind);
            dests[num_dests] <- {ind=ind, loc=loc};
            num_dests += 1;
        }
    }
    if (cargo.effect != GSCargo.TE_NONE) {
        // Find towns with sufficient rating.
        local acceptable_ratings = [
                GSTown.TOWN_RATING_MEDIOCRE,    GSTown.TOWN_RATING_GOOD,
                GSTown.TOWN_RATING_VERY_GOOD,   GSTown.TOWN_RATING_EXCELLENT,
                GSTown.TOWN_RATING_OUTSTANDING, GSTown.TOWN_RATING_INVALID
        ];

        foreach (town, _ in GSTownList()) {
            local rating = GSTown.GetRating(town, company);
            if (rating in acceptable_ratings) {
                local loc = GSTown.GetLocation(town);
                dests[num_dests] <- {town=town, loc=loc};
                num_dests += 1;
            }
        }
    }
    return dests;
}

// Construct a score for the distance
// @param desired Desired distance.
// @param actual Actual distance.
// @return Score for the distance.
function BusyBeeClass::GetDistanceScore(desired, actual)
{
    if (actual < desired) return 1000 - 3 * (desired - actual); // Too close gets punished hard.
    return 1000 - (actual - desired);
}

// Try to find a challenge for a given cargo and a desired distance.
// @param cargo Cargo entry from BusyBeeClass.cargoes (table with 'cid', 'freight', 'effect').
// @param distance Desired distance between source and target.
// @param cid Company to find a challenge for.
// @return Best accepting industry to use, or 'null' if no industry-pair found.
function BusyBeeClass::FindChallenge(cargo_id, distance, cid)
{
    local prods = this.FindSources(cargo_id);
    local accepts = this.FindDestinations(cargo_id, cid);
    local cdata = this.companies[cid];

    local best_score = 0; // Best overall distance.
    local best_accept = null; // Best accepting to target.
    foreach (_, accept in accepts) {
        if (cdata != null && cdata.HasGoal(cargo_id, accept)) continue; // Prevent duplicates.

        local min_prod_distance = distance * 2; // Smallest found distance to the accepting industry.
        local prod_score = GetDistanceScore(distance, min_prod_distance);
        foreach (_, prod in prods) {
            local actual_dist = GSTile.GetDistanceManhattanToTile(accept.loc, prod.loc);
            if (actual_dist > distance * 2) continue; // Too far away, skip.

            if (actual_dist < min_prod_distance) {
                min_prod_distance = actual_dist;
                prod_score = this.GetDistanceScore(distance, min_prod_distance);
                if (min_prod_distance < distance && prod_score < best_score) break;
            }
        }
        if (prod_score > best_score) { // The accepting industry is better than what we have.
            prod_score = best_score;
            best_accept = accept;
        }
    }
    return best_accept;
}

// Try to add a goal for a company.
function BusyBeeClass::CreateChallenge(cid)
{
    local attempt = 0;
    while (attempt < 20) {
        local cargo = GSBase.RandRange(this.num_cargoes);
        local distance = GSBase.RandRange(200) + 50; // Distance 50 .. 250 tiles.
        local accept = FindChallenge(cargo, distance, cid);
        if (accept != null) {
            local cdata = this.companies[cid];
            local amount = GSBase.RandRange(100) + 1;
            if (amount < 10) {
                amount = amount * 25; // 25 .. 225
            } else if (amount < 10 + 35) {
                amount = 10 * 25 + (amount - 10) * 50; // 250..1950
            } else {
                amount = 10 * 25 + 35 * 50 + (amount - 10 - 35) * 100; // 2000..7500
            }
            if (cdata != null) {
                cdata.AddActiveGoal(cargo, accept, amount);

                local destination_name;
                if ("town" in accept) {
                    destination_name = GSTown.GetName(accept.town);
                } else {
                    destination_name = GSIndustry.GetName(accept.ind);
                }
                GSLog.Info("Company " + cid + ": " + amount + " of " +
                           GSCargo.GetCargoLabel(this.cargoes[cargo].cid) +
                           " to " + destination_name);
                break;
            }
        }
        attempt += 1;
    }
}

function BusyBeeClass::Start()
{
    this.Sleep(1); // Wait for the game to start.

    this.ExamineCargoes();

    // Construct empty companies.
    this.companies = {};
    for (local cid = GSCompany.COMPANY_FIRST; cid <= GSCompany.COMPANY_LAST; cid++) {
        this.companies[cid] <- null;
    }

    // Main event loop.
    local companies_timeout = 0;
    local new_goal_timeout = 0;
    local finished_timeout = 0;
    local monitor_timeout = 0;
    local old_cmonitor = null;
    while (true) {
        // Check for new or disappeared companies.
        if (companies_timeout <= 0) {
            for (local cid = GSCompany.COMPANY_FIRST; cid <= GSCompany.COMPANY_LAST; cid++) {
                if (GSCompany.ResolveCompanyID(cid) == GSCompany.COMPANY_INVALID) {
                    if (this.companies[cid] != null) {
                        // XXX Handle company disappearing
                        monitor_timeout = 0; // Force updating of the goals.
                        GSLog.Info("Deleted company " + cid);
                    }
                    this.companies[cid] = null;
                } else {
                    if (this.companies[cid] == null) {
                        this.companies[cid] = CompanyData(cid);
                        GSLog.Info("Created company " + cid);
                    }
                }
            }
            companies_timeout = 50 * 74; // 50 days until the next companies check.
        }

        // Check for having to create new goals.
        if (new_goal_timeout <= 0) {
            local total_missing = 0; // Total number of missing goals.
            local best_cid = null;
            local cid_missing = 0;
            foreach (cid, cdata in companies) {
                if (cdata == null) continue;
                local missing = cdata.GetMissingGoalCount();
                total_missing += missing;

                // Find company with most missing goals.
                if (missing > cid_missing) {
                    best_cid = cid;
                    cid_missing = missing;
                }
            }
            if (best_cid != null) {
                this.CreateChallenge(best_cid);
                monitor_timeout = 0; // Force updating of the monitor.
            }

            if (total_missing > 1) {
                new_goal_timeout = 1 * 74; // If more missing goals, wait only a short while.
            } else {
                new_goal_timeout = 30 * 74;
            }
        }

        // Monitoring and updating of company goals. Note that code above may force an update.
        if (monitor_timeout <= 0) {
            local cmon = {};
            // Collect monitors that are of interest.
            foreach (cid, cdata in companies) {
                if (cdata == null) continue;
                cdata.AddMonitorElements(cmon);
            }

            if (old_cmonitor == null) { // First run, clear any old monitoring.
                GSCargoMonitor.StopAllMonitoring();
                old_cmonitor = {};
            }
            this.FillMonitors(cmon); // Query the monitors.

            // Distribute the retrieved data.
            local finished = false;
            foreach (cid, cdata in companies) {
                if (cdata == null) continue;
                if (cdata.UpdateDelivereds(cmon)) finished = true;
            }

            // Drop obsolete monitors.
            this.UpdateCompanyMonitors(old_cmonitor, cmon);
            old_cmonitor = cmon;

            monitor_timeout = 15 * 74; // By default, check monitors every 15 days (other processes may force a check earlier).
            if (finished) finished_timeout = 0;
        }

        // Check for finished goals, and remove them if they exist.
        if (finished_timeout <= 0) {
            foreach (cid, cdata in companies) {
                if (cdata == null) continue;
                cdata.CheckAndFinishGoals();
            }

            finished_timeout = 30 * 74; // By default, check for finished goals every 30 days (may be forced by other processes).
        }

//        local lake_news = GSText(GSText.STR_LAKE_NEWS);
//        GSNews.Create(GSNews.NT_GENERAL, lake_news, GSCompany.COMPANY_INVALID);
//        GSGoal.Question(1, GSCompany.COMPANY_INVALID, lake_news, GSGoal.QT_INFORMATION, GSGoal.BUTTON_GO);

        // Sleep until the next event.
        local delay_time = 5000;
        if (delay_time > companies_timeout) delay_time = companies_timeout;
        if (delay_time > new_goal_timeout)  delay_time = new_goal_timeout;
        if (delay_time > monitor_timeout)   delay_time = monitor_timeout;
        if (delay_time > finished_timeout)  delay_time = finished_timeout;

        // XXX Perhaps check for company events?
//        GSLog.Info("");
//        GSLog.Info("Sleeping for " + delay_time + " ticks.");
        if (delay_time > 0) this.Sleep(delay_time);

        companies_timeout -= delay_time;
        new_goal_timeout  -= delay_time;
        monitor_timeout   -= delay_time;
        finished_timeout  -= delay_time;
    }
}

// Fill company monitors with monitored amounts.
// @param [inout] cmon Table of 'comp_id' number to 'cargo_id' number to
//      'ind' and/or 'town' to resource indices to 'null'.
function BusyBeeClass::FillMonitors(cmon)
{
    foreach (comp_id, mon in cmon) {
        foreach (cargo_id, rmon in mon) {
            if ("ind" in rmon) {
                foreach (ind_id, _ in rmon.ind) {
                    local amount = GSCargoMonitor.GetIndustryDeliveryAmount(comp_id, cargo_id, ind_id, true);
                    rmon.ind[ind_id] = amount;
//                    local text = "Industry " + GSIndustry.GetName(ind_id) + " received " + amount +
//                                " units for company " + comp_id +
//                                ", cargo " + GSCargo.GetCargoLabel(cargo_id);
//                   GSLog.Info(text);
                }
            }
            if ("town" in rmon) {
                foreach (town_id, _ in rmon.town) {
                    local amount = GSCargoMonitor.GetTownDeliveryAmount(comp_id, cargo_id, town_id, true);
                    rmon.town[town_id] = amount;
//                   local text = "Town " + GSTown.GetName(town_id) + " received " + amount +
//                                " units for company " + comp_id +
//                                ", cargo " + GSCargo.GetCargoLabel(cargo_id);
//                   GSLog.Info(text);
                }
            }
        }
    }
}

function BusyBeeClass::UpdateCompanyMonitors(old_cmon, cmon)
{
    foreach (comp_id, old_mon in old_cmon) {
        if (comp_id in cmon) {
            this.UpdateCargoMonitors(comp_id, old_mon, cmon[comp_id]);
        } else {
            this.UpdateCargoMonitors(comp_id, old_mon, {});
        }
    }
}

function BusyBeeClass::UpdateCargoMonitors(comp_id, old_mon, mon)
{
    foreach (cargo_id, old_rmon in old_mon) {
        if (cargo_id in mon) {
            this.UpdateResourceMonitors(comp_id, cargo_id, old_rmon, mon[cargo_id]);
        } else {
            this.UpdateResourceMonitors(comp_id, cargo_id, old_rmon, {});
        }
    }
}

function BusyBeeClass::UpdateResourceMonitors(comp_id, cargo_id, old_rmon, rmon)
{
    if ("town" in old_rmon) {
        if ("town" in rmon) {
            this.UpdateTownMonitors(comp_id, cargo_id, old_rmon.town, rmon.town);
        } else {
            this.UpdateTownMonitors(comp_id, cargo_id, old_rmon.town, {});
        }
    }
    if ("ind" in old_rmon) {
        if ("ind" in rmon) {
            this.UpdateIndMonitors(comp_id, cargo_id, old_rmon.ind, rmon.ind);
        } else {
            this.UpdateIndMonitors(comp_id, cargo_id, old_rmon.ind, {});
        }
    }
}

function BusyBeeClass::UpdateTownMonitors(comp_id, cargo_id, old_tmon, tmon)
{
    foreach (town_id, _ in old_tmon) {
        if (!(town_id in tmon)) {
            GSCargoMonitor.GetTownDeliveryAmount(comp_id, cargo_id, town_id, false);
            local text = "Stop monitoring town " + GSTown.GetName(town_id) +
                         "for company " + comp_id + ", cargo " + GSCargo.GetCargoLabel(cargo_id);
            GSLog.Info(text);
        }
    }
}

function BusyBeeClass::UpdateIndMonitors(comp_id, cargo_id, old_imon, imon)
{
    foreach (ind_id, _ in old_imon) {
        if (!(ind_id in imon)) {
            GSCargoMonitor.GetIndustryDeliveryAmount(comp_id, cargo_id, ind_id, false);
            local text = "Stop monitoring industry " + GSIndustry.GetName(ind_id) +
                         "for company " + comp_id + ", cargo " + GSCargo.GetCargoLabel(cargo_id);
            GSLog.Info(text);
        }
    }
}
