// Company related data.

// A goal for a company.
class CompanyGoal {
    cargo = null;         // Cargo data (#Cargo)
    accept = null;        // Accepting resource.
    wanted_amount = null; // Amount to deliver for achieving the goal.
    delivered_amount = 0; // Amount delivered so far.
    goal_id = null;       // Number of the goal in OpenTTD goal window.
    timeout = null;       // Timeout in ticks before the goal becomes obsolete.

    constructor(comp_id, cargo, accept, wanted_amount) {
        this.cargo = cargo;
        this.accept = accept;
        this.wanted_amount = wanted_amount;
        this.timeout = 60 * 30 * 74; // 60 months timeout (30 days, 74 ticks).

        // Construct goal.
        local destination, destination_string, goal_type;
        if ("town" in this.accept) {
            destination = accept.town;
            destination_string = GSText(GSText.STR_TOWN_NAME, destination);
            goal_type = GSGoal.GT_TOWN;
        } else {
            destination = accept.ind;
            destination_string = GSText(GSText.STR_INDUSTRY_NAME, destination);
            goal_type = GSGoal.GT_INDUSTRY;
        }
        local goal_text = GSText(GSText.STR_COMPANY_GOAL, cargo.cid, this.wanted_amount, destination_string);
        this.goal_id = GSGoal.New(comp_id, goal_text, goal_type, destination);
    }

    function AddMonitorElement(mon);
    function UpdateDelivered(mon);
    function UpdateTimeout(step);
    function CheckFinished();
    function FinalizeGoal();
};

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
function CompanyGoal::UpdateDelivered(mon)
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
            } else {
                perc = 100 * this.delivered_amount / this.wanted_amount;
                if (perc > 100) perc = 100;
            }
            local progress_text = GSText(GSText.STR_PROGRESS, perc);
            GSGoal.SetProgress(this.goal_id, progress_text);
        }
    }
}

// Update the timeout of the goal
// @param step Number of passed ticks.
function CompanyGoal::UpdateTimeout(step)
{
    this.timeout -= step;
    if (this.goal_id != null) {
        local remaining = this.timeout;
        if (remaining < 0) remaining = 0;
        if (this.delivered_amount > 0) return; // Don't print remaining ticks when there is cargo delivered.
        local progress_text = GSText(GSText.STR_TIMEOUT, remaining);
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

class CompanyData {
    comp_id = null;

    active_goals = null;

    constructor(comp_id)
    {
        this.active_goals = {};
        this.comp_id = comp_id;

        for (local num = 0; num < 5; num += 1) this.active_goals[num] <- null;
    }

    function FinalizeCompany();

    function GetMissingGoalCount();
    function AddActiveGoal(cargo, accept, amount);
    function HasGoal(cargo_id, accept);
    function GetNumberOfGoalsForCargo(cargo_id);
    function IndustryClosed(ind_id);

    function AddMonitorElements(cmon);
    function UpdateDelivereds(cmon);
    function UpdateTimeout(step);
    function CheckAndFinishGoals();
};

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
            goal.UpdateDelivered(cmon[this.comp_id]);
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
