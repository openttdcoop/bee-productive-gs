// Company related data.

class CompanyData {
    cid = null;

    active_goals = {};

    constructor(cid) {
        this.cid = cid;

        for (local num = 0; num < 5; num += 1) this.active_goals[num] <- null;
    }

    function GetMissingGoalCount();
    function AddActiveGoal(cargo_id, accept, amount);
    function HasGoal(cargo_id, accept);
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
            this.active_goals[num] = {cid=cargo_id, accept=accept, amount=amount};
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
        if (goal.cid != cargo_id) continue;
        if ("town" in accept) {
            if ("ind" in goal.accept || accept.town != goal.accept.town) continue;
        } else {
            if ("town" in goal.accept || accept.ind != goal.accept.ind) continue;
        }
        return true;
    }
    return false;
}
