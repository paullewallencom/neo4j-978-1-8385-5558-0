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

MATCH (A:Node {name: "A"})
MATCH (G:Node {name: "E"})
CALL algo.shortestPath.stream(A, G, "distance")
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId), cost

/**
╒══════════════════════════╤══════╕
│"algo.getNodeById(nodeId)"│"cost"│
╞══════════════════════════╪══════╡
│{"name":"A"}              │0.0   │
├──────────────────────────┼──────┤
│{"name":"B"}              │10.0  │
├──────────────────────────┼──────┤
│{"name":"C"}              │30.0  │
├──────────────────────────┼──────┤
│{"name":"E"}              │36.0  │
└──────────────────────────┴──────┘
*/
