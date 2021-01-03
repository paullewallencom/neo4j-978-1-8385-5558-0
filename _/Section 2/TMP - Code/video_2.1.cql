//=======================================
// Empty db
MATCH (n)
DETACH DELETE n

//=======================================
// Create a simple graph

CREATE (A:Node {id: "A"})
CREATE (B:Node {id: "B"})
CREATE (C:Node {id: "C"})
CREATE (D:Node {id: "D"})
CREATE (E:Node {id: "E"})
CREATE (A)-[:ROAD {property: 1}]->(B)
CREATE (B)-[:ROAD {property: 2}]->(C)
CREATE (C)-[:ROAD {property: 2}]->(D)
CREATE (D)-[:ROAD {property: 2}]->(E)
CREATE (B)-[:ROAD {property: 0}]->(E)
CREATE (A)-[:TRAIN {property: 0}]->(E)

MATCH (n)
RETURN n

//=======================================
// Streaming data
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, null)
YIELD nodeId, cost
RETURN nodeId, cost

// => result is a table with nodeId and "cost" for going from previous node to this one

// get node name instead of id, more readable result
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, null)
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId).id, cost

// limit the use of relationship to a certain type
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, null, {relationshipQuery: "ROAD"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId).id, cost

// we can do the same for node labels
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, null, {nodeQuery: "Node", relationshipQuery: "ROAD"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId).id, cost

// and even select several labels like this:
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, null, {nodeQuery: "Node|Other", relationshipQuery: "ROAD"})
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId).id, cost


// if we need more control over the range of possible Node/relationships used, we need to go for Cypher projection method:
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath.stream(A, E, "", {
						nodeQuery: 'MATCH (n:Node) RETURN id(n) as id', 
                        relationshipQuery: 'MATCH (n)-[r:ROAD]->(m) WHERE r.property > 0 RETURN id(n) as source, id(m) as target',
                        graph: "cypher"
                   }
)
YIELD nodeId, cost
RETURN algo.getNodeById(nodeId).id, cost


//=======================================
// all of the above does not change the initial graph
// we might want to choose to save the algorithm result as a graph property instead of streaming the result (very useful for large graphs!)
// 1. call the algorithm
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath(A, E, null, {writeProperty: "cost"})
YIELD nodeCount, totalCost, loadMillis, evalMillis, writeMillis
RETURN nodeCount, totalCost, loadMillis, evalMillis, writeMillis

// 2. see the results
MATCH (n:Node)
WHERE n.cost IS NOT NULL
RETURN n


// All of the above related to cypher projection is also valid
MATCH (A:Node {id: "A"})
MATCH (E:Node {id: "E"})
CALL algo.shortestPath(A, E, "", {
                        writeProperty: "cost2",
			nodeQuery: 'MATCH (n:Node) RETURN id(n) as id', 
                        relationshipQuery: 'MATCH (n)-[r:ROAD]->(m) WHERE r.property > 0 RETURN id(n) as source, id(m) as target',
                        graph: "cypher"
                   }
)
YIELD nodeCount, totalCost, loadMillis, evalMillis, writeMillis
RETURN nodeCount, totalCost, loadMillis, evalMillis, writeMillis

MATCH (n:Node)
WHERE n.cost2 IS NOT NULL
RETURN n


// Show only the relationships:
MATCH (n:Node)
WHERE n.cost2 IS NOT NULL
WITH n
ORDER BY n.cost2
WITH collect(n) as path
UNWIND range(0, size(path)-1) AS index
WITH path[index] AS current, path[index+1] AS next
MATCH (current)-[r]->(next)
RETURN current, r, next

// + Browser trick to not show "￼Connect result nodes"
