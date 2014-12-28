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

function FMainClass::Start()
{
    this.ExamineCargoes();

//    foreach(idx, val in cargoes) {
//        GSLog.Info(idx + " : " + GSCargo.GetCargoLabel(val.cid) + ", " + val.cid + ", " + val.freight + ", " + val.effect);
//    }

    for (local cid = 0; cid < 32; cid += 1) {
        if (!GSCargo.IsValidCargo(cid)) continue;
        local label = cid + " (" + GSCargo.GetCargoLabel(cid) + ")"
        if (GSCargo.IsFreight(cid)) {
            GSLog.Info(label + " is freight.");
            local accept_inds = GSIndustryList_CargoAccepting(cid);
            local prod_inds = GSIndustryList_CargoProducing(cid);
            foreach (industry,_ in prod_inds) {
                GSLog.Info("Produces " + label + " @ " + GSIndustry.GetName(industry));
            }
            foreach (industry,_ in accept_inds) {
                GSLog.Info("Accepts " + label + " @ " + GSIndustry.GetName(industry));
            }
        } else if (GSCargo.GetTownEffect(cid) != GSCargo.TE_NONE) {
            GSLog.Info(label + " affects town.");
        } else {
            GSLog.Info(label + " does nothing.");
        }
    }

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
        this.Sleep(50);
    }
}
