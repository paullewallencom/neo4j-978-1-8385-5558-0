/**
Alternative routes
*/


// museum
:param start => "Louvre-Rivoli"

// to shopping
:param end => "Grands Boulevards"

MATCH (startNode:Station {name:$start})
MATCH (endNode:Station {name:$end})
CALL algo.kShortestPaths.stream(startNode, endNode, 3, 'time' ,{})
YIELD index, nodeIds, costs
RETURN [node in algo.getNodesById(nodeIds) | node.name] AS stations,
       reduce(acc = 0.0, cost in costs | acc + cost) AS totalCost



/**
1. Take into account time to change line in each station

2. Only select those paths whose end stations have disabled people access

3. Limit number of line changes

4. I am in the museum, I have 1h before leaving to the airport, which places can I still see?

5. My hostel in near the "Champ-Elysées" avenue. I want to see the Eiffel Tower, the Louvre museum and ... as fast as possible. Which path should I use?

*/


// 1:
:param start => "Louvre-Rivoli"
:param end => "Grands Boulevards"

MATCH (startNode:Station {name: $start})
MATCH (endNode:Station {name: $end})
CALL algo.shortestPath.stream(startNode, endNode, 'time')
YIELD nodeId, cost
WITH collect(algo.getNodeById(nodeId)) as path, collect(cost) as travelCostSoFar
UNWIND path as p
RETURN travelCostSoFar[size(path)-1] + sum(coalesce(p.time, 10)) as totalCostWithChanges

// UNWIND range(0, size(path)-1) as index
// WITH path[index] as node, path[index+1] as next, travelCost

// MATCH (node)-[r]->(next)
// RETURN node.name, next.name, count(r), travelCost


// WITH coalesce(node.time, 0) as totalCost
// RETURN sum(totalCost)

// WITH collect(algo.getNodeById(nodeId)) as path, sum(cost) as travelCost
// UNWIND range(0, size(path)-1) as index
// WITH path[index] as node, path[index+1] as next, travelCost
// MATCH (node)-[r]->(next)
// RETURN node.name, next.name, count(r), travelCost


// 2:

// works but makes no sense...

MATCH (startNode:Station {name: $start})
MATCH (endNode:Station {name: $end})
CALL algo.kShortestPaths.stream(startNode, endNode, 5, "time")
YIELD index, nodeIds, costs
WITH index, algo.getNodesById(nodeIds[1..-1]) AS path, costs
WITH index, path, path[0] as startNode, path[size(path)-1] as endNode, costs
WHERE coalesce(endNode.accessibility, true) = true
RETURN path,costs


// 3:

// ongoing
MATCH (startNode:Station {name: $start})
MATCH (endNode:Station {name: $end})
CALL algo.shortestPath.stream(startNode, endNode, '')
YIELD nodeId, cost
WITH collect(algo.getNodeById(nodeId)) as path, sum(cost) as travelCost
UNWIND range(0, size(path)-1) as index
WITH path[index] as node, path[index+1] as next, travelCost
MATCH (node)-[r]->(next)
RETURN node.name, next.name, count(r), travelCost


// 4:

MATCH (n:Station {name: "Louvre-Rivoli"})
CALL algo.shortestPath.deltaStepping.stream(n, "time", 1.0)
YIELD nodeId, distance
WITH algo.getNodeById(nodeId) AS node, distance / 60 as dist
WHERE dist < 60 * 60 // AND n.accessibility = 1
RETURN node.name AS end, dist
ORDER BY dist DESC

// 5: