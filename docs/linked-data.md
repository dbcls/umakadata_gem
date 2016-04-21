# 4 rules

1. Use URIs as names for things
2. Use HTTP URIs so that people can look up those names.
3. When someone looks up a URI, provide useful information, using the standards (RDF*, SPARQL)
4. Include links to other URIs. so that they can discover more things.

# Algorithm

Assume that all subjects might be things. Check only the subject.

## 1. Use URIs as names for things

Whether the results of the following SPARQL query is empty:

```
SELECT
   *
WHERE {
   GRAPH ?g { { ?s ?p ?o } .
              FILTER( !isURI(?s) )
            }
}
LIMIT 1
```

## 2. Use HTTP URIs so that people can look up those names

Whether the results of the following SPARQL query is empty:

```
SELECT
   *
WHERE {
   GRAPH ?g { { ?s ?p ?o } .
              FILTER( !contains(str(?s), 'http://') )
            }
}
LIMIT 1
```
## 3. When someone looks up a URI, provide useful information, using the standards (RDF*, SPARQL)

Access the URIs which are randomly retrieved, then the server returns expected status code.
Consider how retrieve data randomly...

## 4. Include links to other URIs. so that they can discover more things.

VOID contains this information.
Retrieve entries whose predicate is sameAs of seeAlso.
Search the entry where the graph of the subject and one of object is different.
