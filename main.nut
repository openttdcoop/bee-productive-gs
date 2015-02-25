/*
 * This file is part of BusyBee, which is a GameScript for OpenTTD
 * Copyright (C) 2014-2015  alberth / andythenorth
 *
 * BusyBee is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * BusyBee is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with BusyBee; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA 02110-1301 USA.
 */

require("company.nut");

// Cargo description.
class Cargo
{
    index   = null; ///< Index of the cargo in the cargo table (#BusyBeeClass.cargoes).
    cid     = null; ///< Id of the cargo in GRF.
    freight = null; ///< Whether the cargo is considered to be freight.
    effect  = null; ///< Town effect (One of #GSCargo.TownEffect).
    weight  = null; ///< Likelihood of picking this cargo for making a goal.

    constructor(index, cid, freight, effect)
    {
        this.index = index;
        this.cid = cid;
        this.freight = freight;
        this.effect = effect;
        this.weight = this.GetWeight(effect);
    }

    function GetWeight();
}

// Get the weight of the cargo (probability of selecting it).
// @param effect Town effect of the cargo.
function Cargo::GetWeight(effect)
{
    if (effect == GSCargo.TE_PASSENGERS) return GSController.GetSetting("pass_weight");
    if (effect == GSCargo.TE_MAIL)       return GSController.GetSetting("mail_weight");
    if (effect != GSCargo.TE_NONE)       return GSController.GetSetting("town_weight");
    return 1;
}

// ************************************************************************
// ************************************************************************

class BusyBeeClass extends GSController
{
    cargoes = null;  ///< Cargoes of the game (index -> 'cid' number, 'freight' boolean, 'effect' on town).
    num_cargoes = 0; ///< Number of cargoes in 'this.cargoes'.
    sum_weight = 0;  ///< Total sum of the weights of the cargoes.

    companies = null;

    loaded = false;

    function Load(version, data);
    function Save();
    function Start();
}

function BusyBeeClass::Load(version, data)
{
    this.loaded = true;
    this.Initialize();

    foreach (comp_id, loaded_comp_data in data) {
        local cdata = CompanyData.LoadCompany(comp_id, loaded_comp_data, this.cargoes);
        this.companies[comp_id] = cdata;
    }
}

function BusyBeeClass::Save()
{
    local result = {};
    foreach (comp_id, cdata in this.companies) {
        if (cdata == null) continue;
        result[comp_id] <- cdata.SaveCompany();
    }
    return result;
}

// Initialize core data of the script.
function BusyBeeClass::Initialize()
{
    if (this.companies != null) return; // Already initialized.

    // Examine and store cargo types of the game.
    this.cargoes = {};
    this.num_cargoes = 0;
    this.sum_weight = 0;

    for (local cid = 0; cid < 32; cid += 1) {
        if (!GSCargo.IsValidCargo(cid)) continue;

        local cargo = Cargo(this.num_cargoes, cid, GSCargo.IsFreight(cid),  GSCargo.GetTownEffect(cid));
        this.cargoes[this.num_cargoes] <- cargo;
        this.num_cargoes += 1;
        this.sum_weight += cargo.weight;
    }

    // Construct empty companies.
    this.companies = {};
    for (local comp_id = GSCompany.COMPANY_FIRST; comp_id <= GSCompany.COMPANY_LAST; comp_id++) {
        this.companies[comp_id] <- null;
    }
}

// Find cargo sources.
// @param cargo_index Cargo index (index in this.cargoes).
// @return List of resources that produce the requested cargo, list of
//      'ind' or 'town' number, 'prod' produced amount, 'transp' transported amount, and 'loc' location.
function BusyBeeClass::FindSources(cargo_index)
{
    local cargo = this.cargoes[cargo_index];
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
// Dump sources for a cargo.
//    GSLog.Info("Sources for " + GSCargo.GetCargoLabel(cargo.cid));
//    foreach (_, src in sources) {
//        if ("ind" in src) {
//            GSLog.Info("Industry " + GSIndustry.GetName(src.ind) + " produces " + src.prod);
//        } else {
//            GSLog.Info("Town " + GSTown.GetName(src.town) + " produces " + src.prod);
//        }
//    }
//    GSLog.Info("");

    return sources;
}

// Find destinations for the cargo.
// @param cargo_index Cargo index (index in this.cargoes).
// @param company Company to inspect.
// @return A list of destinations, tables 'ind' or 'town' id, and a 'loc' location.
function BusyBeeClass::FindDestinations(cargo_index, company)
{
    local cargo = this.cargoes[cargo_index];
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
                local amount = GSTile.GetCargoAcceptance(loc, cargo.cid, 1, 1, 4);
                if (amount > 8) {
                    dests[num_dests] <- {town=town, loc=loc};
                    num_dests += 1;
                }
            }
        }
    }
// Dump destinations for a cargo.
//    GSLog.Info("Destinations for " + GSCargo.GetCargoLabel(cargo.cid));
//    foreach (_, dst in dests) {
//        if ("ind" in dst) {
//            GSLog.Info("Industry " + GSIndustry.GetName(dst.ind) + " accepts");
//        } else {
//            GSLog.Info("Town " + GSTown.GetName(dst.town) + " accepts");
//        }
//    }
//    GSLog.Info("");
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
// @param cargo_index Index in BusyBeeClass.cargoes.
// @param distance Desired distance between source and target.
// @param comp_id Company to find a challenge for.
// @return Best accepting industry to use, or 'null' if no industry-pair found.
function BusyBeeClass::FindChallenge(cargo_index, distance, comp_id)
{
    local prods = this.FindSources(cargo_index);
    if (prods.len() == 0) return null;
    local accepts = this.FindDestinations(cargo_index, comp_id);
    if (accepts.len() == 0) return null;

    local cdata = this.companies[comp_id];
    local cargo = this.cargoes[cargo_index];

    local best_score = 0; // Best overall distance.
    local best_accept = null; // Best accepting to target.
    foreach (_, accept in accepts) {
        if (cdata != null && cdata.HasGoal(cargo.cid, accept)) continue; // Prevent duplicates.

        local min_prod_distance = distance * 2; // Smallest found distance to the accepting industry.
        local prod_score = best_score;
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

// Select the next cargo to use for a goal.
// @return The index of the cargo to use in this.cargoes.
function BusyBeeClass::SelectCargo()
{
    local remaining = GSBase.RandRange(this.sum_weight);
    local cargo_index = 0;
    foreach (cargo in this.cargoes) {
        GSLog.Info("sum_weight=" + this.sum_weight + ", remain=" + remaining + ", weight=" + cargo.weight +
                   "index=" + cargo_index);
        if (remaining < cargo.weight) return cargo_index;
        remaining -= cargo.weight;
        cargo_index += 1;
    }
    return -1; // Should never be reached.
}

// Try to add a goal for a company.
// @param comp_id Company to find a challenge for.
function BusyBeeClass::CreateChallenge(comp_id)
{
    local cdata = this.companies[comp_id];
    for (local attempt = 0;attempt < 20; attempt += 1) {
        local cargo_index = this.SelectCargo();
        if (cargo_index < 0) continue;

        local cargo = this.cargoes[cargo_index];
        if (cdata.GetNumberOfGoalsForCargo(cargo.cid) > 1) continue; // Already 2 goals for this cargo.
        local distance = GSBase.RandRange(200) + 50; // Distance 50 .. 250 tiles.
        local accept = FindChallenge(cargo_index, distance, comp_id);
        if (accept != null) {
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

                local dest_name;
                if ("town" in accept) {
                    dest_name = GSTown.GetName(accept.town);
                } else {
                    dest_name = GSIndustry.GetName(accept.ind);
                }
                GSLog.Info("Company " + comp_id + ": " + amount + " of " +
                           GSCargo.GetCargoLabel(cargo.cid) + " to " + dest_name);
                break;
            }
        }
    }
}

// Process events that arrived.
// @return Table with 'force_goal' bool to force goal updating.
function BusyBeeClass::ProcessEvents()
{
    local force_goal = false;
    while (GSEventController.IsEventWaiting()) {
        local event = GSEventController.GetNextEvent();
        local event_type = event.GetEventType();

        if (event_type == GSEvent.ET_COMPANY_NEW) {
            local comp_id = GSEventCompanyNew.Convert(event).GetCompanyID();
            if (this.companies[comp_id] == null) {
                this.companies[comp_id] = CompanyData(comp_id);
                GSLog.Info("Created company " + comp_id + " (newly started).");
                force_goal = true;
            }

        } else if (event_type == GSEvent.ET_COMPANY_MERGER) {
            local comp_id = GSEventCompanyMerger.Convert(event).GetOldCompanyID();
            if (this.companies[comp_id] != null) {
                this.companies[comp_id].FinalizeCompany();
                this.companies[comp_id] = null;
                GSLog.Info("Deleted company " + comp_id + " (due to merging).");
            }
        } else if (event_type == GSEvent.ET_COMPANY_BANKRUPT) {
            local comp_id = GSEventCompanyBankrupt.Convert(event).GetCompanyID();
            if (this.companies[comp_id] != null) {
                this.companies[comp_id].FinalizeCompany();
                this.companies[comp_id] = null;
                GSLog.Info("Deleted company " + comp_id + " (no monies anymore).");
            }

        } else if (event_type == GSEvent.ET_INDUSTRY_CLOSE) {
            local ind_id = GSEventIndustryClose.Convert(event).GetIndustryID();
            foreach (comp_id, cdata in this.companies) {
                if (cdata != null) cdata.IndustryClosed(ind_id);
            }
        }
    }
    return {force_goal=force_goal};
}

// Check if new goals should be created.
// @return Table with 'more_goals_needed' boolean, and 'force_monitor' to force updating.
function BusyBeeClass::TryAddNewGoal()
{
    local force_monitor=false;

    local total_missing = 0; // Total number of missing goals.
    local best_comp_id = null;
    local comp_id_missing = 0;
    foreach (comp_id, cdata in this.companies) {
        if (cdata == null) continue;
        local missing = cdata.GetMissingGoalCount();
        total_missing += missing;

        // Find company with most missing goals.
        if (missing > comp_id_missing) {
            best_comp_id = comp_id;
            comp_id_missing = missing;
        }
    }
    if (best_comp_id != null) {
        this.CreateChallenge(best_comp_id);
        force_monitor = true; // Force updating of the monitor to get the monitoring switched on.
    }

    return {force_monitor=force_monitor, more_goals_needed=(best_comp_id != null && total_missing > 1)};
}

// Update progress on existing monitored goals, add monitoring for new goals, and drop monitors for removed goals.
// @param old_cmon Monitored deliveries (or 'null' if first call).
// @return Table 'cmon' with the new monitored deliveries, 'finished_goals' boolean when there exist goals that are completed.
function BusyBeeClass::UpdateDeliveries(old_cmon)
{
    if (old_cmon == null) { // First run, clear any old monitoring.
        GSCargoMonitor.StopAllMonitoring();
        old_cmon = {};
    }

    local cmon = {};
    // Collect monitors that are of interest.
    foreach (comp_id, cdata in this.companies) {
        if (cdata == null) continue;
        cdata.AddMonitorElements(cmon);
    }

    this.FillMonitors(cmon); // Query the monitors for new deliveries.

    // Distribute the retrieved data.
    local finished = false;
    foreach (comp_id, cdata in this.companies) {
        if (cdata == null) continue;
        if (cdata.UpdateDelivereds(cmon)) finished = true;
    }

    // Drop obsolete monitors.
    this.UpdateCompanyMonitors(old_cmon, cmon);

    return {cmon=cmon, finished_goals=finished};
}

// The script data got loaded from file, check it against the game.
function BusyBeeClass::CompaniesPostLoadCheck()
{
    // Check companies.
    for (local comp_id = GSCompany.COMPANY_FIRST; comp_id <= GSCompany.COMPANY_LAST; comp_id++) {
        if (GSCompany.ResolveCompanyID(comp_id) == GSCompany.COMPANY_INVALID) {
            if (this.companies[comp_id] != null) {
                this.companies[comp_id].FinalizeCompany();
                this.companies[comp_id] = null;
                GSLog.Info("Deleted company " + comp_id + " (disappeared after loading).");
            }
        } else {
            if (this.companies[comp_id] == null) {
                this.companies[comp_id] = CompanyData(comp_id);
                GSLog.Info("Created company " + comp_id + " (appeared from nowhere after loading).");
            }
        }
    }

    // Check industries used for goals.
    foreach (comp_id, cdata in this.companies) {
        if (cdata == null) continue;
        cdata.GoalsPostLoadCheck();
    }
}

function BusyBeeClass::Start()
{
    this.Initialize();
    this.Sleep(1); // Wait for the game to start.

    local cmonitor = null;
    if (this.loaded) { // Script data was loaded.
        this.CompaniesPostLoadCheck();
        cmonitor = {}; // Don't kill existing monitors after loading.
    }

    // Main event loop.
    local new_goal_timeout = 0;
    local finished_timeout = 0;
    local monitor_timeout = 0;
    while (true) {
        local result = this.ProcessEvents();
        if (result.force_goal) new_goal_timeout = 0;

        // Check for having to create new goals.
        if (new_goal_timeout <= 0) {
            local result = this.TryAddNewGoal();
            if (result.force_monitor) monitor_timeout = 0;

            if (result.more_goals_needed) {
                new_goal_timeout = 1 * 74;
            } else {
                new_goal_timeout = 30 * 74;
            }
        }

        // Monitoring and updating of company goals. Note that code above may force an update.
        if (monitor_timeout <= 0) {
            local result = this.UpdateDeliveries(cmonitor);
            cmonitor = result.cmon;
            if (result.finished_goals) finished_timeout = 0;

            monitor_timeout = 15 * 74; // By default, check monitors every 15 days (other processes may force a check earlier).
        }

        // Check for finished goals, and remove them if they exist.
        if (finished_timeout <= 0) {
            foreach (comp_id, cdata in this.companies) {
                if (cdata == null) continue;
                cdata.CheckAndFinishGoals();
            }

            finished_timeout = 30 * 74; // By default, check for finished goals every 30 days (may be forced by other processes).
        }

//        local lake_news = GSText(GSText.STR_LAKE_NEWS);
//        GSNews.Create(GSNews.NT_GENERAL, lake_news, GSCompany.COMPANY_INVALID);
//        GSGoal.Question(1, GSCompany.COMPANY_INVALID, lake_news, GSGoal.QT_INFORMATION, GSGoal.BUTTON_GO);

        // Sleep until the next event.
        local delay_time = 5 * 74; // Check events every 5 days.
        if (delay_time > new_goal_timeout)  delay_time = new_goal_timeout;
        if (delay_time > monitor_timeout)   delay_time = monitor_timeout;
        if (delay_time > finished_timeout)  delay_time = finished_timeout;

        if (delay_time > 0) this.Sleep(delay_time);

        new_goal_timeout  -= delay_time;
        monitor_timeout   -= delay_time;
        finished_timeout  -= delay_time;

        // Update timeout of the goals as well.
        if (!GSGame.IsPaused()) {
            foreach (comp_id, cdata in this.companies) {
                if (cdata == null) continue;
                cdata.UpdateTimeout(delay_time);
            }
        }
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
// Dump received amount of cargo of an industry.
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
// Dump received amount of cargo of a town.
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
                         " for company " + comp_id + ", cargo " + GSCargo.GetCargoLabel(cargo_id);
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
                         " for company " + comp_id + ", cargo " + GSCargo.GetCargoLabel(cargo_id);
            GSLog.Info(text);
        }
    }
}
