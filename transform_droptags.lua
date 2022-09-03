--
-- If an object has name:cy, use that as name
--

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
