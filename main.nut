class FMainClass extends GSController 
{
    function Start();
}

function FMainClass::Start()
{
//    for (local cid = 0; cid < 32; cid += 1) {
//        if (!GSCargo.IsValidCargo(cid)) continue;
//        if (GSCargo.IsFreight(cid)) {
//            GSLog.Info(cid + " is freight.");
//        } else if (GSCargo.GetTownEffect(cid) != GSCargo.Town_Effect.TE_NONE) {
//            GSLog.Info(cid + " affects town.");
//        } else {
//            GSLog.Info(cid + " does nothing.");
//        }
//    }
    while (true) {
        if (GSBase.Chance(1, 5)) {
            GSLog.Info("We're at at the bottom of the lake.");
        } else {
            GSLog.Info("We're not at the bottom of the lake.");
        }
//        GSLog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(50);
    }
}
