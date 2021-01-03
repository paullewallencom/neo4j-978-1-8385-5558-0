/**
Import data

 1. Go to "" and download all csv files
 2. Create database in Neo4j Desktop (do not start it yet)
 3. In "Manage" window, go to "Terminal" tab
 4. Copy all csv into `import` folder
 5. Use neo4j import tool with following command:

     bin/neo4j-admin import --nodes "import/nodes_ALL.csv" --relationships "import/relations_ALL.csv"

297 nodes
712 relationships

*/

/**
Look at the graph content

1. Start graph
2. Open browser
*/

// DB content:
// Check in browser
// Nodes: Station
// Relationships: SUBWAY

// DB graph

MATCH (n:Station)
RETURN n
LIMIT 100


/**
Find shortest path between two Stations
*/

// museum
//
MATCH (n:Station)
WHERE n.name CONTAINS "Louvre"
RETURN n

:param start => "Louvre-Rivoli"

// to shopping
:param end => "Grands Boulevards"

/*
Simple call with streamed results
*/

MATCH (startNode:Station {name: $start})
MATCH (endNode:Station {name: $end})
CALL algo.shortestPath.stream(startNode, endNode, '')
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

// graph & text view => in text view you can see the cost

/*
shortestPath procedure parameters

- WeightProperty
*/

MATCH (startNode:Station {name: $start})
MATCH (endNode:Station {name: $end})
CALL algo.shortestPath.stream(startNode, endNode, 'time')
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

// if we take into account time, the chosen path is different!

/*
shortestPath procedure parameters

- Direction
To see the impact of this parameter, we will change our starting and ending point to include one of the "loops" we've already noticed, for instance on line 10

Three possible values for this parameter: "BOTH", "OUTGOING", "INCOMING"
*/

// B
:param B => 'Boulogne-Jean-Jaurès'
// C
:param C => 'Charles Michels'

MATCH (start:Station {name: $B})
MATCH (end:Station {name: $C})
CALL algo.shortestPath.stream(start, end, 'time', {direction: "BOTH"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

MATCH (start:Station {name: $B})
MATCH (end:Station {name: $C})
CALL algo.shortestPath.stream(start, end, 'time', {direction: "INCOMING"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

MATCH (start:Station {name: $B})
MATCH (end:Station {name: $C})
CALL algo.shortestPath.stream(start, end, 'time', {direction: "OUTGOING"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

// We can also use symbols:
// "OUTGOING" = ">" = "OUT" = "o"
// "INCOMING" = "<" = "IN" = "i"
// "BOTH"= "<>" = "b"