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
};

function CompanyData::GetMissingGoalCount()
{
    local missing = 0;
    foreach (num, goal in this.active_goals) {
        if (goal == null) missing += 1;
    }
    return missing;
}

function CompanyData::AddActiveGoal(cargo_id, accept, amount)
{
    foreach (num, goal in this.active_goals) {
        if (goal == null) {
            this.active_goals[num] = {cid=cargo_id, accept=accept, amount=amount};
            break;
        }
    }
}
