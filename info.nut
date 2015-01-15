/*
 * This file is part of BusyBee, which is a GameScript for OpenTTD
 * Copyright (C) 2014-2015  alberth / andythenorth
 *
 * BusyBee is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * BusyBee is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with BusyBee; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA 02110-1301 USA.
 */

SAVEGAME_VERSION <- 1; // Set manually if/when save games break.
MINCOMPATIBLE_SAVEGAME_VERSION <- 1; // cset: 06b75370997d

PROGRAM_VERSION <- Syntax error, set by 'make bundle'.
PROGRAM_DATE <- Syntax error, set by 'make bundle'.
PROGRAM_NAME <- Syntax error, set by 'make bundle'.

class BusyBeeInfo extends GSInfo {
    function GetAuthor()        { return "alberth & andythenorth"; }
    function GetName()          { return PROGRAM_NAME; }
    function GetDescription()   { return "Make connection, transport cargo"; }
    function GetVersion()       { return PROGRAM_VERSION + SAVEGAME_VERSION * 100000; }
    function GetDate()          { return PROGRAM_DATE; }
    function CreateInstance()   { return "BusyBeeClass"; }
    function GetShortName()     { return "BBEE"; }
    function GetAPIVersion()    { return "1.5"; }
    function GetUrl()           { return "http://dev.openttdcoop.org/projects/busy-bee-gs"; }
    function MinVersionToLoad() { return MINCOMPATIBLE_SAVEGAME_VERSION; }
    function GetSettings();
}

function BusyBeeInfo::GetSettings()
{
    GSInfo.AddSetting({name="num_goals",
                       description="Number of goals for a company",
                       min_value=1,
                       max_value=10,
                       easy_value=5,
                       medium_value=5,
                       hard_value=5,
                       custom_value=5,
                       flags=GSInfo.CONFIG_NONE});
    GSInfo.AddSetting({name="wait_years",
                       description="Number of years to wait to fulfill a new goal",
                       min_value=4,
                       max_value=20,
                       easy_value=10,
                       medium_value=5,
                       hard_value=3,
                       custom_value=7,
                       flags=GSInfo.CONFIG_INGAME});
}

RegisterGS(BusyBeeInfo());
