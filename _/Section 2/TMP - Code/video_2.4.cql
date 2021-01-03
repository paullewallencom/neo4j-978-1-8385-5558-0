WITH [	
    // start, end, distance
	["A", "B", 10],
      	["A", "C", 33],
	["A", "D", 35],
	["C", "D", 28],
	["B", "C", 20],
	["C", "E", 6],
	["D", "E", 40]
] AS nested
UNWIND nested AS row
MERGE (n:Node {name: row[0]})
MERGE (m:Node {name: row[1]})
MERGE (n)-[r:LINK {distance: row[2]}]->(m)

// k-shortest paths

MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL algo.kShortestPaths.stream(A, E, 5, "distance")
YIELD index, nodeIds, costs
RETURN index, nodeIds,costs

// let's show node names instead of ids
MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL algo.kShortestPaths.stream(A, E, 5, "distance")
YIELD index, nodeIds, costs
RETURN index,
       [node in algo.getNodesById(nodeIds[1..-1]) | node.name] AS nodes,
       costs

// or total cost
MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL algo.kShortestPaths.stream(A, E, 5, "distance")
YIELD index, nodeIds, costs
RETURN index,
       [node in algo.getNodesById(nodeIds[1..-1]) | node.name] AS nodes,
       costs,
       reduce(tmp = 0.0, c in costs | tmp + c) AS total_cost


// Nice feature: returning the path
MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL algo.kShortestPaths.stream(A, E, 1, 'time', {path: true})
YIELD path
RETURN path

// Write back results in the graph
MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL algo.kShortestPaths(A, E, 3, 'time' ,{})
YIELD resultCount
RETURN resultCount

// see the path as new relationships!
MATCH p=(A:Node {name: "A"})-[r:PATH_0|PATH_1|PATH_2*]->(E:Node {name: "E"}) 
RETURN p


// Single source shortest path
MATCH (n:Node {name:"A"})
CALL algo.shortestPath.deltaStepping.stream(n, "distance", 1.0)
YIELD nodeId, distance
RETURN algo.getNodeById(nodeId).name AS end, distance
ORDER BY distance

/**
Dist from A to E infinite?
=> due to the relationships with no "distance"!

Two solutions:
1. Clear the graph

    MATCH ()-[r:PATH_0|PATH_1|PATH_2]-()
    DELETE r

2. Or filter out those relationships using the relationshipQuery
*/
MATCH (n:Node {name:"A"})
CALL algo.shortestPath.deltaStepping.stream(n, "distance", 10.0, {relationshipQuery:"LINK"})
YIELD nodeId, distance
RETURN algo.getNodeById(nodeId).name AS end, distance
ORDER BY distance

/*
NB: in some cases, the distance will really by infinite, in case there is not path between nodes
*/

CREATE (:Node {name: "F"})

MATCH (n:Node {name:"A"})
CALL algo.shortestPath.deltaStepping.stream(n, "distance", 10.0, {relationshipQuery:"LINK"})
YIELD nodeId, distance
RETURN algo.getNodeById(nodeId).name AS end, distance
ORDER BY distance

// GAL contains helper function to filter thos nodes out
MATCH (n:Node {name:"A"})
CALL algo.shortestPath.deltaStepping.stream(n, "distance", 10.0, {relationshipQuery:"LINK"})
YIELD nodeId, distance
WHERE algo.isFinite(distance)
RETURN algo.getNodeById(nodeId).name AS end, distance
ORDER BY distance

// or to select only those nodes if we want to identify them:
MATCH (n:Node {name:"A"})
CALL algo.shortestPath.deltaStepping.stream(n, "distance", 10.0, {relationshipQuery:"LINK"})
YIELD nodeId, distance
WHERE NOT algo.isFinite(distance)
RETURN algo.getNodeById(nodeId).name AS end, distance
ORDER BY distance


// All pairs shortest path

CALL algo.allShortestPaths.stream('distance')
YIELD sourceNodeId, targetNodeId, distance
WHERE distance > 0
RETURN algo.getNodeById(sourceNodeId).name as sourceNode,
       algo.getNodeById(targetNodeId).name as endNode,
       distance
ORDER BY distance

// C-E = 1 ?
// because we still have in our graph the result of the previous query with PATH_*
// 2 sollutions
// Either clean the graph as above
// or use the relationtypeQuery parameter:

CALL algo.allShortestPaths.stream('distance',
     { nodeQuery:'Node',
     relationshipQuery: 'LINK'})
YIELD sourceNodeId, targetNodeId, distance
WHERE distance > 0
RETURN algo.getNodeById(sourceNodeId).name as sourceNode,
       algo.getNodeById(targetNodeId).name as endNode,
       distance
ORDER BY distance
