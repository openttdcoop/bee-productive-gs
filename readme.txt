===============
Busy Bee readme
===============

Manual for the really Busy Bees
===============================

- Activate the game script,
- Start new game,
- Pick a goal from the goal window to do,
- Make a connection from a supplier to the given destination for the requested
  cargo type,
- Transport the cargo,
- Pick next goal to connect.


Manual for the less Busy Bees
=============================

Busy Bee is a game script for OpenTTD 1.5 or newer.

The script gives a number of goals to achieve (number of goals can be set by a
parameter). It requests a given amount of cargo of a given type to deliver to a
given destination within a time frame. You have to build the transport
connection, and deliver the requested amount. When that is done, the goal is
considered to be fulfilled. It is removed from the list, and a new goal is
created (may take a while) for you to fulfill.

You don't get anything when you fulfill the goal. There is also no penalty for
failing to achieve a goal. The purpose of the timer is to get rid of obsolete
or unreachable goals. (For example, the last oil wells disappeared from the map
before you could finish the oil goal.) You can increase the length of the timer
with a parameter.

License
=======

Busy Bee
Copyright (C) 2015  andythenorth and alberth

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
