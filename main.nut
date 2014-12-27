class FMainClass extends GSController
{
    function Start();
}

function FMainClass::Start()
{
    for (local cid = 0; cid < 32; cid += 1) {
        if (!GSCargo.IsValidCargo(cid)) continue;
        local label = cid + " (" + GSCargo.GetCargoLabel(cid) + ")"
        if (GSCargo.IsFreight(cid)) {
            GSLog.Info(label + " is freight.");
        } else if (GSCargo.GetTownEffect(cid) != GSCargo.TE_NONE) {
            GSLog.Info(label + " affects town.");
        } else {
            GSLog.Info(label + " does nothing.");
        }
    }

    while (true) {
        local lake_news = GSText(GSText.STR_LAKE_NEWS);
        if (GSBase.Chance(1, 5)) {
            GSLog.Info("We're at at the bottom of the lake.");
            lake_news.AddParam(100);
        } else {
            GSLog.Info("We're not at the bottom of the lake.");
            lake_news.AddParam(200);
        }
        GSNews.Create(GSNews.NT_GENERAL, lake_news, GSCompany.COMPANY_INVALID);
		GSGoal.Question(1, GSCompany.COMPANY_INVALID, lake_news, GSGoal.QT_INFORMATION, GSGoal.BUTTON_GO);
//        GSLog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(50);
    }
}
