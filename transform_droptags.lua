--
-- Remove tags from boundary ways that we are not interested in.
--
-- Copyright (C) 2022-2025  Andy Townsend
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- -----------------------------------------------------------------------------

function process(object)
    object.tags.barrier = nil
    object.tags.building = nil
    object.tags.highway = nil
    object.tags.landuse = nil
    object.tags.office = nil
    object.tags.place = nil
    object.tags.waterway = nil

    return object.tags
end

function ott.process_node(object)
    return process(object)
end

function ott.process_way(object)
    return process(object)
end

function ott.process_relation(object)
    return process(object)
end
