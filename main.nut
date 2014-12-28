class FMainClass extends GSController
{
    cargoes = null; // Cargoes of the game (index -> 'cid' number, 'freight' boolean, 'effect' on town).

    function Start();
}

// Examine and store cargo types of the game.
function FMainClass::ExamineCargoes()
{
    this.cargoes = {};
    local num_cargoes = 0;

    for (local cid = 0; cid < 32; cid += 1) {
        if (!GSCargo.IsValidCargo(cid)) continue;

        local is_freight = GSCargo.IsFreight(cid);
        local town_effect = GSCargo.GetTownEffect(cid);
        cargoes[num_cargoes] <- {cid=cid, freight=is_freight, effect=town_effect};
        num_cargoes += 1;
    }
}

// Construct a score for the distance
// @param desired Desired distance.
// @param actual Actual distance.
// @return Score for the distance.
function FMainClass::GetDistanceScore(desired, actual)
{
    if (actual < desired) return 1000 - 3 * (desired - actual); // Too close gets punished hard.
    return 1000 - (actual - desired);
}

// Try to find a challenge for a given cargo and a desired distance.
// @param cargo Cargo entry from FMainClass.cargoes (table with 'cid', 'freight', 'effect').
// @param distance Desired distance between source and target.
// @return Best accepting industry to use, or 'null' if no industry-pair found.
function FMainClass::FindChallenge(cargo, distance)
{
    if (cargo.freight) {
        local prod_inds = GSIndustryList_CargoProducing(cargo.cid); // Cache the list of producers.

        local best_score = 0; // Best overall distance.
        local best_accept_ind = null; // Best industry to target.
        foreach (accept_ind, _ in GSIndustryList_CargoAccepting(cargo.cid)) {
            local accept_tile = GSIndustry.GetLocation(accept_ind);

            local min_prod_distance = distance * 2; // Smallest found distance to the accepting industry.
            local prod_score = GetDistanceScore(distance, min_prod_distance);
            foreach (prod_ind, _ in prod_inds) {
                if (prod_ind == accept_ind) continue;
                local actual_dist = GSIndustry.GetDistanceManhattanToTile(prod_ind, accept_tile);
                if (actual_dist > distance * 2) continue; // Too far away, skip.

                if (actual_dist < min_prod_distance) {
                    min_prod_distance = actual_dist;
                    prod_score = this.GetDistanceScore(distance, min_prod_distance);
                    if (min_prod_distance < distance && prod_score < best_score) break;
                }
            }
            if (prod_score > best_score) { // The accepting industry is better than what we have.
                prod_score = best_score;
                best_accept_ind = accept_ind;
            }
        }
        return best_accept_ind;
    }
    return null; // XXX Town stuff not implemented yet.
}

function FMainClass::Start()
{
    this.ExamineCargoes();

//    foreach(idx, val in cargoes) {
//        GSLog.Info(idx + " : " + GSCargo.GetCargoLabel(val.cid) + ", " + val.cid + ", " + val.freight + ", " + val.effect);
//    }

    local accept_ind = FindChallenge(cargoes[3], 50);
    if (accept_ind != null) {
        GSLog.Info("Use " + GSIndustry.GetName(accept_ind));
    }

//    for (local cid = 0; cid < 32; cid += 1) {
//        if (!GSCargo.IsValidCargo(cid)) continue;
//        local label = cid + " (" + GSCargo.GetCargoLabel(cid) + ")"
//        if (GSCargo.IsFreight(cid)) {
//            GSLog.Info(label + " is freight.");
//            local accept_inds = GSIndustryList_CargoAccepting(cid);
//            local prod_inds = GSIndustryList_CargoProducing(cid);
//            foreach (industry,_ in prod_inds) {
//                GSLog.Info("Produces " + label + " @ " + GSIndustry.GetName(industry));
//            }
//            foreach (industry,_ in accept_inds) {
//                GSLog.Info("Accepts " + label + " @ " + GSIndustry.GetName(industry));
//            }
//        } else if (GSCargo.GetTownEffect(cid) != GSCargo.TE_NONE) {
//            GSLog.Info(label + " affects town.");
//        } else {
//            GSLog.Info(label + " does nothing.");
//        }
//    }

    while (true) {
        local lake_news = GSText(GSText.STR_LAKE_NEWS);
        if (GSBase.Chance(1, 5)) {
//            GSLog.Info("We're at at the bottom of the lake.");
//            lake_news.AddParam(100);
        } else {
//            GSLog.Info("We're not at the bottom of the lake.");
//            lake_news.AddParam(200);
        }
//        GSNews.Create(GSNews.NT_GENERAL, lake_news, GSCompany.COMPANY_INVALID);
//        GSGoal.Question(1, GSCompany.COMPANY_INVALID, lake_news, GSGoal.QT_INFORMATION, GSGoal.BUTTON_GO);
//        GSLog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(5000);
    }
}
