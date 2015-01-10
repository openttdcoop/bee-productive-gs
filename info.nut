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

class BusyBeeInfo extends GSInfo {
    function GetAuthor()        { return "alberth & andythenorth"; }
    function GetName()          { return "BusyBee"; }
    function GetDescription()   { return "Make connection, transport cargo"; }
    function GetVersion()       { return 1; }
    function GetDate()          { return "2015-01-10"; }
    function CreateInstance()   { return "BusyBeeClass"; }
    function GetShortName()     { return "BBEE"; }
    function GetAPIVersion()    { return "1.5"; }
    function GetUrl()           { return ""; }
    function MinVersionToLoad() { return 1; }
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
