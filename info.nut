/*
 * This file is part of BeeProductive, which is a GameScript for OpenTTD
 * Copyright (C) 2014-2015  alberth / andythenorth
 *
 * BeeProductive is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * BeeProductive is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with BeeProductive; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA 02110-1301 USA.
 */

SAVEGAME_VERSION <- 4; // Set manually if/when save games break.
MINCOMPATIBLE_SAVEGAME_VERSION <- 4; // cset: 041c0cf3c573

PROGRAM_VERSION <- Syntax error, set by 'make bundle'.
PROGRAM_DATE <- Syntax error, set by 'make bundle'.
PROGRAM_NAME <- Syntax error, set by 'make bundle'.

class BeeProductiveInfo extends GSInfo {
    function GetAuthor()        { return "alberth, andythenorth & zuu"; }
    function GetName()          { return "Bee Productive"; } // Old: return PROGRAM_NAME;
    function GetDescription()   { return "Make connection, transport cargo to upgrade industries. Fork of Busy Bee. Requires gs->NewGRF patch and imesseger-v2.grf"; }
    function GetVersion()       { return PROGRAM_VERSION + SAVEGAME_VERSION * 100000; }
    function GetDate()          { return PROGRAM_DATE; }
    function CreateInstance()   { return "BeeProductiveClass"; }
    function GetShortName()     { return "PBEE"; }
    function GetAPIVersion()    { return "1.5"; }
    function GetUrl()           { return ""; }
    function MinVersionToLoad() { return MINCOMPATIBLE_SAVEGAME_VERSION; }
    function GetSettings();
}

function BeeProductiveInfo::GetSettings()
{
    GSInfo.AddSetting({name="num_goals",
                       description="Number of goals for a company (1-10)",
                       min_value=1,
                       max_value=10,
                       easy_value=5,
                       medium_value=5,
                       hard_value=5,
                       custom_value=5,
                       flags=GSInfo.CONFIG_NONE});
    GSInfo.AddSetting({name="wait_years",
                       description="Time to wait before first delivery (4-20 year)",
                       min_value=1,
                       max_value=20,
                       easy_value=10,
                       medium_value=5,
                       hard_value=3,
                       custom_value=7,
                       flags=GSInfo.CONFIG_INGAME});
    GSInfo.AddSetting({name="cargo_mp",
                       description="Cargo amount multiplier (50-2000%)",
                       min_value=50,
                       max_value=2000,
                       easy_value=50,
                       medium_value=500,
                       hard_value=1000,
                       custom_value=100,
                       step_size = 10,
                       flags=GSInfo.CONFIG_INGAME});
    GSInfo.AddSetting({name="pass_weight",
                       description="Likelihood of selecting passengers as goal (1-20)",
                       min_value=1,
                       max_value=20,
                       easy_value=1,
                       medium_value=1,
                       hard_value=1,
                       custom_value=1,
                       flags=GSInfo.CONFIG_INGAME});
    GSInfo.AddSetting({name="mail_weight",
                       description="Likelihood of selecting mail as goal (1-20)",
                       min_value=1,
                       max_value=20,
                       easy_value=1,
                       medium_value=1,
                       hard_value=1,
                       custom_value=1,
                       flags=GSInfo.CONFIG_INGAME});
    GSInfo.AddSetting({name="town_weight",
                       description="Likelihood of selecting other town cargoes as goal (1-20)",
                       min_value=1,
                       max_value=20,
                       easy_value=1,
                       medium_value=1,
                       hard_value=1,
                       custom_value=1,
                       flags=GSInfo.CONFIG_INGAME});
}

RegisterGS(BeeProductiveInfo());
