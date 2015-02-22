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

// A goal for a company.
class CompanyGoal {
    cargo = null;         // Cargo data (#Cargo)
    accept = null;        // Accepting resource.
    wanted_amount = null; // Amount to deliver for achieving the goal.
    delivered_amount = 0; // Amount delivered so far.
    goal_id = null;       // Number of the goal in OpenTTD goal window.
    timeout = null;       // Timeout in ticks before the goal becomes obsolete.

    displayed_string = null;
    displayed_count = null;

    // Construct a company goal.
    // @param comp_id Company owning the goal. Use \c null if no OpenTTD goal should be created.
    // @param cargo Cargo that should be delivered.
    // @param accept Accepting resource.
    // @param wanted_amount Amount of cargo that should be delivered to fulfil the goal.
    constructor(comp_id, cargo, accept, wanted_amount) {
        this.cargo = cargo;
        this.accept = accept;
        this.wanted_amount = wanted_amount;

        local years = GSController.GetSetting("wait_years");
        this.timeout = years * 365 * 74;
        while (years >= 4) {
            this.timeout += 74; // Add one day for every 4 years.
            years -= 4;
        }
        if (years >= 2) this.timeout += 74 / 2; // And 1/2 a day for 2 years.

        // Construct goal if a company id was provided.
        if (comp_id != null) {
            local destination, destination_string, destination_string_news, goal_type;
            if ("town" in this.accept) {
                destination = accept.town;
                destination_string = GSText(GSText.STR_TOWN_NAME, destination);
                destination_string_news = GSText(GSText.STR_TOWN_NAME_NEWS, destination);
                goal_type = GSGoal.GT_TOWN;
            } else {
                destination = accept.ind;
                destination_string = GSText(GSText.STR_INDUSTRY_NAME, destination);
                destination_string_news = GSText(GSText.STR_INDUSTRY_NAME_NEWS, destination);
                goal_type = GSGoal.GT_INDUSTRY;
            }
            local goal_text = GSText(GSText.STR_COMPANY_GOAL, cargo.cid,
                                     this.wanted_amount, destination_string);
            this.goal_id = GSGoal.New(comp_id, goal_text, goal_type, destination);
            local goal_news_text = GSText(GSText.STR_COMPANY_GOAL_NEWS, cargo.cid,
                                     this.wanted_amount, destination_string_news);
            this.PublishNews(goal_news_text, comp_id);
        }
    }

    function AddMonitorElement(mon);
    function UpdateDelivered(mon, comp_id);
    function UpdateTimeout(step);
    function CheckFinished();
    function FinalizeGoal();
    function PublishNews(str, comp_id);

    function SaveGoal();
    static function LoadGoal(num, loaded_data);
};

function CompanyGoal::SaveGoal()
{
    return {cid=this.cargo.cid, accept=this.accept, wanted=this.wanted_amount,
            delivered=this.delivered_amount, goal=this.goal_id, timeout=this.timeout};
}

// Load an existing goal.
// @param loaded_data Data of the goal.
// @param cargoes Cargoes of the game.
// @return The loaded goal, if loading went ok.
function CompanyGoal::LoadGoal(loaded_data, cargoes)
{
    local goal = null;
    foreach (cargo_num, cargo in cargoes) {
        if (cargo.cid == loaded_data.cid) {
            goal = CompanyGoal(null, cargo, loaded_data.accept, loaded_data.wanted);
            goal.delivered_amount = loaded_data.delivered;
            goal.goal_id = loaded_data.goal;
            goal.timeout = loaded_data.timeout;
            return goal;
        }
    }
    return null;
}

// Add an entry to the collection of monitored things.
// @param [inout] mon Table with 'cargo_id' to 'town' and 'ind' tables, holding ids to 'null'.
function CompanyGoal::AddMonitorElement(mon)
{
    if (!(this.cargo.cid in mon)) mon[this.cargo.cid] <- {};
    mon = mon[this.cargo.cid];
    if ("ind" in this.accept) {
        if (!("ind" in mon)) mon.ind <- {};
        mon.ind[this.accept.ind] <- null;
    } else {
        if (!("town" in mon)) mon.town <- {};
        mon.town[this.accept.town] <- null;
    }
}

// Update the delivered amount from the monitored amounts.
function CompanyGoal::UpdateDelivered(mon, comp_id)
{
    local delivered;
    if ("ind" in this.accept) {
        delivered = mon[this.cargo.cid].ind[this.accept.ind];
    } else {
        delivered = mon[this.cargo.cid].town[this.accept.town];
    }

    if (delivered > 0) {
        this.delivered_amount += delivered;
        if (this.goal_id != null) {
            local perc;
            if (this.delivered_amount >= this.wanted_amount) {
                perc = 100;
                GSGoal.SetCompleted(this.goal_id, true);
                local destination_string_news;
                if ("town" in this.accept) {
                    destination_string_news = GSText(GSText.STR_TOWN_NAME_NEWS, this.accept.town);
                } else {
                    destination_string_news = GSText(GSText.STR_INDUSTRY_NAME_NEWS, this.accept.ind);
                }
                local goal_won_news = GSText(GSText.STR_COMPANY_GOAL_WON_NEWS, cargo.cid,
                                         this.wanted_amount, destination_string_news);
                this.PublishNews(goal_won_news, comp_id);
            } else {
                perc = 100 * this.delivered_amount / this.wanted_amount;
                if (perc > 100) perc = 100;
            }
            local progress_text = GSText(GSText.STR_PROGRESS, perc);
            GSGoal.SetProgress(this.goal_id, progress_text);
        }
    }
}

// Get the number of days in the given month for the given year.
// @param month Month of the year (1..12).
// @param year The provided year.
// @return Number of days of the given month and day combination.
function CompanyGoal::GetNumberOfDaysInMonth(month, year)
{
    // http://www.codecodex.com/wiki/Calculate_the_number_of_days_in_a_month#C.2FC.2B.2B

    if (month == 4 || month == 6 || month == 9 || month == 11) {
        return 30;
    } else if (month == 2) {
        if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
            return 29;
        } else {
            return 28;
        }
    } else {
        return 31;
    }
}

// Get the amount of time between two dates.
// @param start First date.
// @param end Second date.
// @return The number of day/month/year between both dates.
// @note Since months have varying length, the day count may be off somewhat.
function CompanyGoal::GetTimeBetweenDates(start, end)
{
    if (start >= end) return {days=0, months=0, years=0};

    local start_year = GSDate.GetYear(start);
    local end_year = GSDate.GetYear(end);

    local num_months = 0;
    while (start_year < end_year) {
        start_year += 1;
        num_months += 12;
    }

    local start_month = GSDate.GetMonth(start);
    local end_month = GSDate.GetMonth(end);
    if (start_month <= end_month) {
        num_months += end_month - start_month;
    } else {
        num_months -= start_month - end_month;
    }

    local start_day = GSDate.GetDayOfMonth(start);
    local end_day = GSDate.GetDayOfMonth(end);
    local num_days;
    if (start_day <= end_day) {
        num_days = end_day - start_day;
    } else {
        num_months -= 1;
        if (end_month == 1) {
            start_month = 12;
        } else {
            start_month = end_month - 1;
        }
        num_days = this.GetNumberOfDaysInMonth(start_month, end_year) - start_day + end_day;
    }

    return {days=num_days, months=num_months % 12, years=num_months / 12};
}

// Update the timeout of the goal
// @param step Number of passed ticks.
function CompanyGoal::UpdateTimeout(step)
{
    this.timeout -= step;
    if (this.goal_id != null) {
        if (this.delivered_amount > 0) return; // Don't print remaining ticks when there is cargo delivered.

        local remaining = this.timeout;
        if (remaining < 0) remaining = 0;

        local now = GSDate.GetCurrentDate();
        local between = this.GetTimeBetweenDates(now, now + remaining / 74);

        local str_to_show, count_to_use;
        if (between.years >= 2) {
            str_to_show = GSText.STR_TIMEOUT_YEARS;
            count_to_use = between.years;
        } else if (between.years == 1) {
            str_to_show = GSText.STR_TIMEOUT_MONTHS;
            count_to_use = 12 + between.months;
        } else if (between.months > 0) {
            str_to_show = GSText.STR_TIMEOUT_MONTHS;
            count_to_use = between.months;
        } else {
            str_to_show = GSText.STR_TIMEOUT_DAYS;
            count_to_use = between.days;
        }

        // If string or number changed, update the text in the goal window.
        if (str_to_show == this.displayed_string && count_to_use == this.displayed_count) return;

        this.displayed_string = str_to_show;
        this.displayed_count = count_to_use;
        local progress_text = GSText(this.displayed_string, this.displayed_count);
        GSGoal.SetProgress(this.goal_id, progress_text);
    }
}

// Test whether the goal can be considered 'done' (or obsolete).
// @return Whether the goal is considered done.
function CompanyGoal::CheckFinished()
{
    return this.timeout < 0 || this.delivered_amount >= this.wanted_amount;
}

// Goal is considered 'done', last chance to clean up before the goal is dropped
// (to make room for a new goal).
function CompanyGoal::FinalizeGoal()
{
    if (this.goal_id != null) GSGoal.Remove(this.goal_id);
}

// Publish a news item about the goal.
// @param news_text String with text to publish.
// @param comp_id Company owning the goal.
function CompanyGoal::PublishNews(news_text, comp_id)
{
    const RELEASED_MASK = 0x80000; // 1 << 19;
    const RELEASE_START_BIT = 20;
    const NIGHTLY_MASK = 0x7FFFF;  // RELEASED_MASK - 1;

    local version = GSController.GetVersion();
    local add_position = false;
    if ((version & RELEASED_MASK) == RELEASED_MASK) {
        add_position = (version >> RELEASE_START_BIT) >= (1 << 8) + (5 << 4); // 1.5.0 release or later.
    } else {
        add_position = (version & NIGHTLY_MASK) >= (27164 & NIGHTLY_MASK); // nightly >= r27164.
    }
    if (add_position) {
        if ("town" in this.accept) {
            GSNews.Create(GSNews.NT_GENERAL, news_text, comp_id, GSNews.NR_TOWN, this.accept.town);
        } else {
            GSNews.Create(GSNews.NT_GENERAL, news_text, comp_id, GSNews.NR_INDUSTRY, this.accept.ind);
        }
    } else {
        // 1.4, or nightly < 27156, no position information.
        GSNews.Create(GSNews.NT_GENERAL, news_text, comp_id);
    }
}

// ************************************************************************
// ************************************************************************

class CompanyData {
    comp_id = null;

    active_goals = null;

    constructor(comp_id)
    {
        this.active_goals = {};
        this.comp_id = comp_id;

        local num_goals = GSController.GetSetting("num_goals");
        for (local num = 0; num < num_goals; num += 1) this.active_goals[num] <- null;
    }

    function FinalizeCompany();

    function GoalsPostLoadCheck();
    function GetMissingGoalCount();
    function AddActiveGoal(cargo, accept, amount);
    function HasGoal(cargo_id, accept);
    function GetNumberOfGoalsForCargo(cargo_id);
    function IndustryClosed(ind_id);

    function AddMonitorElements(cmon);
    function UpdateDelivereds(cmon);
    function UpdateTimeout(step);
    function CheckAndFinishGoals();

    function SaveCompany();
    static function LoadCompany(comp_id, loaded_data);
};

// Save company data.
function CompanyData::SaveCompany()
{
    local result = {};
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        result[num] <- goal.SaveGoal();
    }
    return result;
}

// Load company data from the file, constructing a new company.
// @param comp_id Company id.
// @param loaded_data Data to load for this company.
// @param cargoes Cargoes of the game.
// @return The created company.
function CompanyData::LoadCompany(comp_id, loaded_data, cargoes)
{
    local cdata = CompanyData(comp_id);
    foreach(num, loaded_goal_data in loaded_data) {
        cdata.active_goals[num] = CompanyGoal.LoadGoal(loaded_goal_data, cargoes);
    }
    return cdata;
}

// Company is about to be deleted, last chance to clean up.
function CompanyData::FinalizeCompany()
{
    foreach (num, goal in this.active_goals) {
        if (goal != null) {
            goal.FinalizeGoal();
            this.active_goals[num] = null;
        }
    }
}

// Find the number of active goals that are missing for this company.
// @return Number of additional goals that the company needs.
function CompanyData::GetMissingGoalCount()
{
    local missing = 0;
    foreach (num, goal in this.active_goals) {
        if (goal == null) missing += 1;
    }
    return missing;
}

// Add a goal to the list of the company.
// @param cargo Cargo of the goal (#Cargo).
// @param accept Accepting resource of the goal.
// @param wanted_amount Amount of cargo to deliver.
function CompanyData::AddActiveGoal(cargo, accept, wanted_amount)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) {
            this.active_goals[num] = CompanyGoal(this.comp_id, cargo, accept, wanted_amount);
            break;
        }
    }
}

// Does the company have an active goal for the given cargo and accepting resource?
// @param cargo_id Cargo to check.
// @param accept Accepting resource to check.
// @return Whether the company has a goal for the cargo and resource.
function CompanyData::HasGoal(cargo_id, accept)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if (goal.cargo.cid != cargo_id) continue;
        if ("town" in accept) {
            if ("ind" in goal.accept || accept.town != goal.accept.town) continue;
        } else {
            if ("town" in goal.accept || accept.ind != goal.accept.ind) continue;
        }
        return true;
    }
    return false;
}

// Count the number of goals that ask for the given cargo type.
// @param cargo_id Cargo to check for.
// @return Number of active goals with the given cargo type.
function CompanyData::GetNumberOfGoalsForCargo(cargo_id)
{
    local count = 0;
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if (goal.cargo.cid == cargo_id) count += 1;
    }
    return count;
}

// The given industry closed, delete any goal with it.
// @param ind_id Industry that closed.
function CompanyData::IndustryClosed(ind_id)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if ("ind" in goal.accept && goal.accept.ind == ind_id) {
            goal.FinalizeGoal();
            this.active_goals[num] = null;
        }
    }
}

// Game data was just loaded, check whether the goals make sense.
function CompanyData::GoalsPostLoadCheck()
{
    // Check whether the industries still live.
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if ("ind" in goal.accept && !GSIndustry.IsValidIndustry(goal.accept.ind)) {
            goal.FinalizeGoal();
            this.active_goals[num] = null;
        }
    }
}

// Add monitor elements of a company, if they exist.
// @param [inout] cmon Monitors of all companies, updated in-place.
//      Result is 'comp_id' number to 'cargo_id' numbers to 'ind' and/or 'town' indices to 'null'
function CompanyData::AddMonitorElements(cmon)
{
    local mon = {};
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        goal.AddMonitorElement(mon);
    }
    if (mon.len() == 0) return;

    cmon[this.comp_id] <- mon;
    return;
}

// Distribute the delivered amounts to the goals.
// @param cmon Monitor results of all companies, 'comp_id' numbers to 'cargo_id' number to
//          'ind' and/or 'town' to resource indices to amount.
// @return Whether a goal is considered to be 'done'.
function CompanyData::UpdateDelivereds(cmon)
{
    local finished = false;
    if (this.comp_id in cmon) {
        foreach (num, goal in this.active_goals) {
            if (goal == null) continue;
            goal.UpdateDelivered(cmon[this.comp_id], this.comp_id);
            if (goal.CheckFinished()) finished = true;
        }
    }
    return finished; // One or more goals was considered 'done'
}

function CompanyData::UpdateTimeout(step)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        goal.UpdateTimeout(step);
    }
}

// Test whether goals of the company are 'done', and if so, drop them.
function CompanyData::CheckAndFinishGoals()
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if (goal.CheckFinished()) {
            goal.FinalizeGoal();
            this.active_goals[num] = null;
        }
    }
}

