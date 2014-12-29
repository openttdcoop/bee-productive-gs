// Company related data.

// A goal for a company.
class CompanyGoal {
    cargo_id = null;      // Cargo id
    accept = null;        // Accepting resource.
    wanted_amount = null; // Amount to deliver for achieving the goal.
    delivered_amount = 0; // Amount delivered so far.

    constructor(cargo_id, accept, wanted_amount) {
        this.cargo_id = cargo_id;
        this.accept = accept;
        this.wanted_amount = wanted_amount;
    }

    function AddMonitorElement(mon);
    function UpdateDelivered(mon);
    function CheckFinished();
    function FinalizeGoal();
};

// Add an entry to the collection of monitored things.
// @param [inout] mon Table with 'cargo_id' to 'town' and 'ind' tables, holding ids to 'null'.
function CompanyGoal::AddMonitorElement(mon)
{
    if (!(this.cargo_id in mon)) mon[this.cargo_id] <- {};
    mon = mon[this.cargo_id];
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
        delivered = mon[this.cargo_id].ind[this.accept.ind];
    } else {
        delivered = mon[this.cargo_id].town[this.accept.town];
    }

    this.delivered_amount += delivered;
}

// Test whether the goal can be considered 'done'.
// @return Whether the goal is considered done.
function CompanyGoal::CheckFinished()
{
    return this.delivered_amount >= this.wanted_amount;
}

// Goal is considered 'done', last chance to clean up before the goal is dropped
// (to make room for a new goal).
function CompanyGoal::FinalizeGoal()
{
    // Nothing to do (yet).
}

class CompanyData {
    comp_id = null;

    active_goals = {};

    constructor(comp_id) {
        this.comp_id = comp_id;

        for (local num = 0; num < 5; num += 1) this.active_goals[num] <- null;
    }

    function GetMissingGoalCount();
    function AddActiveGoal(cargo_id, accept, amount);
    function HasGoal(cargo_id, accept);

    function AddMonitorElement(mon);
    function UpdateDelivered(mon);
    function CheckAndFinishGoals();
};

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
// @param cargo_id Cargo of the goal.
// @param accept Accepting resource of the goal.
// @param amount Amount of cargo to deliver.
function CompanyData::AddActiveGoal(cargo_id, accept, amount)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) {
            this.active_goals[num] = CompanyGoal(cargo_id, accept, amount);
            break;
        }
    }
}

// Does the company have an active goal for the given cargo and accepting resource?
// @param cargo_id Cargo to check for.
// @param accept Accepting resource to check.
// @return Whether the company has a goal for the cargo and resource.
function CompanyData::HasGoal(cargo_id, accept)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) continue;
        if (goal.cargo_id != cargo_id) continue;
        if ("town" in accept) {
            if ("ind" in goal.accept || accept.town != goal.accept.town) continue;
        } else {
            if ("town" in goal.accept || accept.ind != goal.accept.ind) continue;
        }
        return true;
    }
    return false;
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
