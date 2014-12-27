/*
 * This file is part of BusyBee, which is a GameScript for OpenTTD
 * Copyright (C) 2014  alberth / andythenorth
 *
 * BusyBee is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * NoCarGoal is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with NoCarGoal; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

class FMainClass extends GSInfo {
    function GetAuthor()        { return "alberth & andythenorth"; }
    function GetName()          { return "BusyBee"; }
    function GetDescription()   { return "Goal: Have fun"; }
    function GetVersion()       { return 0; }
    function GetDate()          { return "2014-12-27"; }
    function CreateInstance()   { return "MainClass"; }
    function GetShortName()     { return "BBEE"; }
    function GetAPIVersion()    { return "1.5"; }
    function GetUrl()           { return ""; }
}

RegisterGS(FMainClass());
