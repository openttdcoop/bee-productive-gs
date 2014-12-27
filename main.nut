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
        if (GSBase.Chance(1, 5)) {
            GSLog.Info("We're at at the bottom of the lake.");
        } else {
            GSLog.Info("We're not at the bottom of the lake.");
        }
        GSNews.Create(GSNews.NT_GENERAL, "There is a fish here", GSCompany.COMPANY_INVALID);
//        GSLog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(50);
    }
}
